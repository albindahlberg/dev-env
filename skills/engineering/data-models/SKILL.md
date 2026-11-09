---
name: data-models
description: Choose data structures and models in Python or TypeScript. Use when writing or refactoring code that defines a record, a closed set of values or variants, a JSON/config shape, input validation, settings, a container, or an interface.
---

# Data models

1. **Match the project first.** Look for how the project already models the
   same kind of data: pydantic, attrs, msgspec, zod, valibot, ORM models, or a
   style guide. Follow what's there. Use the rest of this skill only where the
   project has no pattern of its own.
2. **Read the language file**: [PYTHON.md](PYTHON.md) or
   [TYPESCRIPT.md](TYPESCRIPT.md). It covers the version or compiler flags
   to respect, then each construct in the table below.
3. **Pick by what the data is**, using the table.
4. **Check library APIs** in the current docs before writing calls to a
   validation or settings library (pydantic, pydantic-settings, zod), for
   the version in the lockfile: context7 when it's available, else the
   library's docs site. This skill picks the construct; the docs give its
   exact API.

Done when every data shape the change adds or alters maps to a row of the
table, or to the project's own pattern.

| The data is | Python | TypeScript |
|---|---|---|
| JSON passed through unread, even if another tool owns its schema | `dict` | `unknown` |
| A shape another tool owns that the code reads by fixed keys | `TypedDict`, validated at load | `interface`, validated at load |
| A true mapping (arbitrary keys, lookup table) | `dict` or a specialised container | `Record<K, V>` when serialised, else `Map` |
| An internal record with fixed fields | `@dataclass(frozen=True)` | `interface` with `readonly` fields |
| A small immutable record unpacked positionally | `NamedTuple` | labelled `readonly` tuple |
| A closed set of plain tags | `Literal[...]` | string literal union |
| A closed set with per-member data, an order, or use across modules | `StrEnum` / `Enum` | `as const` object + derived union |
| Combinable options | `enum.Flag` | `ReadonlySet` of a literal union |
| One of several cases, each with its own fields | union of frozen dataclasses | discriminated union |
| External input the code relies on (API bodies, user-edited config) | pydantic `BaseModel` | zod schema + `z.infer` |
| Settings from env vars or `.env` | `BaseSettings` or a dataclass | zod schema over `process.env` |
| A contract that other code satisfies | `Protocol` | `interface` |

## Rules in every language

- **Pass-through stays raw.** Data the program only forwards keeps its raw
  type. Once the code reads a field by name, the data is no longer
  pass-through: validate it, even if it is also forwarded. A wrapper around
  a schema someone else owns adds conversion code that drifts.
- **Validate at the edge.** External data the code depends on is parsed once,
  where it enters, into a typed value, and only typed values travel inward.
- **Make illegal states unrepresentable.** A value that is one of several
  cases is a union of variants, each holding only its own fields, branched on
  with an exhaustive match. A record whose mode depends on which fields are
  null is a union in disguise.
- **One source of truth per shape.** Derive the static type from the schema
  (or the schema from the type) rather than writing both.
- **Immutable by default** for values that cross a module interface; make
  changed copies.
- **Settings load once** at startup and are passed down.
