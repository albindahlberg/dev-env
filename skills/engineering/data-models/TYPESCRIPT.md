# TypeScript data models

Sources: the TypeScript handbook and tsconfig reference
(typescriptlang.org), the Zod 4 docs (zod.dev) and typescript-eslint.

## Compiler flags

Read `tsconfig.json` and write code that passes the flags it sets; change
them only when the issue asks.

- `strict` is assumed; it is the default from TypeScript 6.0.
- `noUncheckedIndexedAccess` adds `undefined` to index-signature and array
  reads, so `sizes[key]` on a `Record<string, number>` is
  `number | undefined`. Narrow it; a `!` hides the case.
- `exactOptionalPropertyTypes` separates a missing key from one set to
  `undefined`. Write `x?: T | undefined` only when both are meant.
- `erasableSyntaxOnly` (5.8+), common with Node's type stripping, rejects
  syntax with runtime behaviour: `enum`, `namespace` with code, parameter
  properties (`constructor(public x: number)`) and `import =`. The patterns
  below already use only erasable syntax.

## interface vs type

The handbook's heuristic: "use `interface` until you need to use features
from `type`". An `interface` names object shapes and extends with `extends`,
which the compiler checks faster than `&` and shows by name in errors. Use
`type` for unions, tuples, mapped and conditional types, and aliases of
primitives.

## Records

An internal record is an `interface` with `readonly` fields. `readonly` and
`Readonly<T>` stop reassignment only at type-check time and are shallow, so
collection fields are `readonly T[]`, `ReadonlyMap` or `ReadonlySet`. Make
changed copies with spread: `{ ...file, stored }`.

A plain object literal is the record; a `class` is for state with behaviour
that guards an invariant.

A small positional record is a labelled readonly tuple:
`readonly [start: Date, end: Date]`.

## Closed sets

A set of plain tags is a string literal union:
`type UploadMode = "shared" | "gdr" | "direct"`.

When members carry data, an order, or are iterated, use an `as const`
object and derive the union, which the handbook gives as the alternative to
`enum`:

```ts
const STATUS = {
  fail: { icon: "✗" },
  ok: { icon: "✓" },
} as const;
type Status = keyof typeof STATUS;
```

For an iterated list of tags, `const MODES = ["shared", "gdr", "direct"] as
const` and `type Mode = (typeof MODES)[number]`. Combinable options are a
`ReadonlySet<Mode>`.

## Variants

A value that is one of several cases is a discriminated union: each member
has a literal `kind` and only its own fields.

```ts
interface Shared { readonly kind: "shared"; readonly objects: ReadonlyMap<FileFormat, DataFileObject> }
interface ViaGdr { readonly kind: "gdr"; readonly client: GdrUploadClient }
interface Direct { readonly kind: "direct"; readonly bucket: Bucket }
type DataFileUpload = Shared | ViaGdr | Direct;

function describe(upload: DataFileUpload): string {
  switch (upload.kind) {
    case "shared": return "shared objects";
    case "gdr": return "via gdr-upload";
    case "direct": return "direct";
    default: {
      const unhandled: never = upload;
      return unhandled;
    }
  }
}
```

The `never` assignment turns a new member without a case into a compile
error. Where typescript-eslint runs with type information, enable
`@typescript-eslint/switch-exhaustiveness-check` to catch the same thing
across every switch.

## Typed tables and config

Check a literal against a type with `satisfies`, which keeps the object's
own inferred keys instead of widening to the annotation:

```ts
const PART_SIZE = { fastq: 5_242_880, bam: 8_388_608 } satisfies Record<FileFormat, number>;
```

A missing or misspelt key is an error. Values still widen (`PART_SIZE.fastq`
is `number`); write `as const satisfies ...` when the literal values matter.

Use `Record<K, V>` for a map over a literal union or one that is serialised,
and `Map` for keys added at runtime or non-string keys. `JSON.stringify`
turns a `Map` into `{}`.

## JSON boundaries

A type that crosses JSON holds only strings, numbers, booleans, `null`,
arrays and plain objects. `Date` comes back as a string, and `Map`, `Set`,
`bigint` and `undefined` don't survive. Carry dates as ISO strings in wire
types and parse them at the edge (`z.iso.datetime()`).

## External input

Data from outside (HTTP bodies, files, `JSON.parse`, message queues) enters
as `unknown`, and is validated by a schema before use. `any` turns checking
off for every value it touches.

With Zod 4:

- Define the schema once at module level and derive the type with
  `type Case = z.infer<typeof Case>`. Use `z.input` / `z.output` when a
  `.transform()` makes them differ.
- `z.object()` strips unknown keys. Use `z.strictObject()` where an unknown
  key means a typo, as in user-edited config, and `z.looseObject()` to pass
  extra keys through.
- `.safeParse()` returns a discriminated result for boundaries that report
  errors to a caller; `.parse()` throws, for input whose failure is a bug.
- Variants: `z.discriminatedUnion("kind", [A, B])`. Closed sets:
  `z.enum(["shared", "gdr", "direct"])`; `z.nativeEnum` is deprecated.
- Zod 4 forms: top-level formats (`z.email()`, `z.uuid()`, `z.url()`),
  `{ error: ... }` for custom messages, `z.record(keySchema, valueSchema)`
  with both arguments.

A project already on valibot, arktype or another validator keeps it; the
same rules apply.

## Settings

Parse `process.env` once at startup with a schema and export the typed
result; the rest of the code imports that object, never `process.env`.
Every env value is a string: use `z.coerce.number()` for numbers and
`z.stringbool()` for flags, since `z.coerce.boolean()` reads `"false"` as
`true`.

## Domain primitives

Identifiers that must not be mixed up get a brand:
`type CaseId = string & { readonly __brand: "CaseId" }`, created only by a
parsing function. Brands are a community pattern, not in the handbook;
follow the project if it has its own.

## Signatures

Accept the widest type the function needs (`readonly T[]`, `Iterable<T>`,
`ReadonlyMap`) and return the concrete one. Derive types with `Pick`,
`Omit`, `ReturnType<typeof f>` and `keyof typeof` instead of restating them,
within a module; across modules, import the owner's exported type.

## Contracts

A contract other code satisfies is an `interface`; implementations declare
it with `implements` when they are classes, or are object literals typed by
it.
