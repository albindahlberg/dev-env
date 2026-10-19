---
name: python-data-models
description: Choose Python data structures and models. Use when writing or refactoring Python that defines a record, a fixed set of values, a JSON/config shape, input validation, settings, a container, or an interface.
---

# Python data models

1. **Match the project first.** Look for how the project already models the
   same kind of data: pydantic, attrs, msgspec, SQLAlchemy/Django models, or a
   style guide. Follow what's there. Use the rest of this skill only where the
   project has no pattern of its own.
2. **Check the version floor.** Read `requires-python`, and assume 3.13 if it's
   absent. Features newer than the floor are marked below.
3. **Pick by what the data is**, using the table:

| The data is | Use |
|---|---|
| JSON passed through unread, even if another tool owns its schema | `dict` |
| A dict shape another tool owns that the code reads by fixed keys | `TypedDict`, validated at load ([TypedDict](#typeddict)) |
| A true mapping (arbitrary keys, lookup table) | `dict`, or a specialised container ([CONTAINERS.md](CONTAINERS.md)) |
| An internal record with fixed fields | `@dataclass` |
| A small immutable record that is unpacked or returned positionally | `NamedTuple` |
| A closed set of plain tags | `Literal[...]` |
| A closed set with per-member data, an order, or use across modules | `StrEnum` / `Enum` |
| Combinable options | `enum.Flag` with `auto()` values |
| External input the code relies on (API bodies, user-edited config) | pydantic `BaseModel` if present or the shape is nested; else `@dataclass` + `__post_init__` |
| Settings from env vars or `.env` | `pydantic-settings` `BaseSettings` if present; else `@dataclass` from `os.environ` |
| A contract that other code satisfies | `Protocol` |

For containers and typing helpers (`defaultdict`, `Counter`, `deque`,
`ChainMap`, `frozenset`, `Mapping` vs `dict` in signatures, `NewType`, `Final`,
`type` aliases), read [CONTAINERS.md](CONTAINERS.md).

## dict vs record

A dict with fixed string keys inside the program, such as `r["status"]` or a
`blank()` factory that returns a dict, is a record, so make it a dataclass.
A dict that only passes through the program, read or forwarded without the
code depending on its shape, stays a dict. A wrapper around a schema that
someone else owns only adds conversion code that drifts. External data that
the code depends on is validated at the edge (see pydantic below).

## dataclass

The default is plain `@dataclass`. Add flags when a rule below applies:

- `frozen=True` when instances are dict keys or set members, or are passed to
  code that must not change them. Hashing needs every field to be hashable, so
  use `tuple` or `frozenset` fields, not `list` or `set`.
- `slots=True` when you expect more than about 10k live instances. It's
  incompatible with `cached_property`, and a class can't inherit from two
  slotted bases.
- `kw_only=True` when two or more adjacent fields share a type and could be
  passed in the wrong order.
- `order=True` when instances get sorted by their fields in declaration order.

Other tools:

- Put mutable defaults in `field(default_factory=list)`.
- Use `field(init=False)` for derived fields that `__post_init__` sets.
- Validate invariants in `__post_init__`, raising `ValueError`.
- Make changed copies with `dataclasses.replace(obj, x=1)`.
- `dataclasses.asdict` recursively deep-copies, so for JSON use
  `json.dumps(asdict(obj))`. For a shallow dict, use
  `{f.name: getattr(obj, f.name) for f in fields(obj)}`.

## NamedTuple

Use a NamedTuple when the code already treats the record as a tuple: unpacking,
sorting, or positional returns. It equals any plain tuple of the same length
and can be indexed by position, so domain objects with identity get a frozen
dataclass instead.

```python
class Finding(NamedTuple):
    key: str
    detail: str
    level: Status
```

## Literal and Enum

Use `Literal["a", "b"]` for plain tags, such as a mode parameter or a field
holding one of a few strings. Type checkers narrow on it, and it costs nothing
at runtime.

Use `StrEnum` (3.11+) when members carry attributes, are iterated, or are
shared across modules. Definition order is iteration order, so declare members
in the order that matters (for example worst-first) and say so in the name or
docstring. Attach per-member data with `__new__`:

```python
class Status(StrEnum):
    icon: str

    FAIL = "fail", "✗"
    OK = "ok", "✓"

    def __new__(cls, value: str, icon: str):
        m = str.__new__(cls, value)
        m._value_ = value
        m.icon = icon
        return m
```

Use `IntEnum` only when the members have to interoperate with integers, such
as exit codes or wire values.

Branch on enums and Literals with `match`, and end it with
`case _: assert_never(x)` so the type checker flags a missing case.

Keys that are only looked up, never iterated or given attributes, stay plain
`str`.

## TypedDict

Use a TypedDict when a dict shape that stays a dict is read in several places
and the project runs a type checker. Mark optional keys with `NotRequired[...]`
and keys code must not write with `ReadOnly[...]`. `ReadOnly` is in `typing`
from 3.13 and in `typing_extensions` before that. A TypedDict is checked only
statically, so validate untrusted input at runtime, with
`TypeAdapter(MyTypedDict)` if pydantic is present.

## pydantic

Use pydantic v2 for data that enters from outside and has to be trusted: API
request and response bodies, webhook payloads, and user-edited JSON/YAML/TOML
that the code relies on. If pydantic isn't in the project yet, add it only when
the shape is nested or validation would take more than a handful of checks.
Otherwise use a dataclass that raises `ValueError` from `__post_init__`.
Internal records stay dataclasses. Validate once at the edge and pass typed
objects inward.

- `BaseModel` is for new boundary shapes. Parse raw JSON with
  `Model.model_validate_json(raw)` rather than `model_validate(json.loads(raw))`.
- `TypeAdapter(T)` validates into an existing dataclass, TypedDict or
  `list[T]` without converting it to a model. Build each adapter once at module
  level and reuse it, because every instantiation compiles a new validator.
- Set `model_config = ConfigDict(extra="forbid")` when an unknown key means a
  typo, as it does in user-edited config. The default silently drops unknown
  keys.
- Annotate model fields with concrete `list` and `tuple`, not `Sequence`.

If `pydantic-settings` is already a dependency, load settings from env vars or
`.env` with it:

```python
class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="app_", env_file=".env")
    db_url: str
    api_key: SecretStr
```

`SecretStr` keeps the value out of reprs and logs. Without `pydantic-settings`,
build a dataclass from `os.environ`. Either way, build settings once at startup
and pass them down.

## Protocol vs ABC

Use a `Protocol` to describe what a function needs from its argument, such as
`class Readable(Protocol): def read(self) -> bytes: ...`. Add
`@runtime_checkable` only when code checks it with `isinstance`. That check
looks only for attribute names, not signatures.

Use an ABC when you own the hierarchy and subclasses share implementation, or
when instantiating a subclass that's missing a method must fail. A single
implementation gets a plain class.

## Multiprocessing

Classes that cross a `multiprocessing` or `ProcessPoolExecutor` spawn boundary
must be defined at module level, because workers unpickle them by import. Enum
members unpickle to the same singleton, so `is` keeps working in workers.
