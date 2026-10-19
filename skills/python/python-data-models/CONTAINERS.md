# Containers and typing helpers

## Specialised containers

| Need | Use |
|---|---|
| Group or accumulate by key | `defaultdict(list)` |
| Count occurrences, top-N | `Counter`, `.most_common(n)` |
| Queue, sliding window, pops from both ends | `deque(maxlen=n)` |
| Layered lookup (CLI over env over defaults) | `ChainMap(cli, env, defaults)` |
| Read-only module-level table | `MappingProxyType(table)` |
| Immutable or hashable set, membership constant | `frozenset` |
| Immutable sequence field | `tuple[X, ...]` |
| Priority queue | `heapq` on a list |
| Sorted insert or lookup | `bisect` on a sorted list |
| Fixed-size chunks | `itertools.batched(xs, n)` (3.12+) |

Use `types.SimpleNamespace` only for throwaway attribute bags in tests. For a
real record, use a dataclass.

## Signatures

- Accept the abstract type and return the concrete one. Parameters take
  `Mapping`, `Sequence` or `Iterable` from `collections.abc`, and returns give
  `dict`, `list` or `tuple`.
- Use builtin generics such as `list[int]` and `dict[str, X]`, and write
  unions as `X | None`.

## Typing helpers

- `NewType("UserId", int)` for domain primitives that must not be mixed up. It
  returns its argument unchanged at runtime, so the value stays an `int`.
- `Final` for module constants and `ClassVar` for class-level fields on a
  dataclass.
- `type Pairs = list[tuple[str, int]]` (3.12+) for a reused complex type. Below
  3.12, use `Pairs: TypeAlias = ...`, which has been deprecated since 3.12.
- `Self` (3.11+) as the return type of fluent methods and alternative
  constructors.
