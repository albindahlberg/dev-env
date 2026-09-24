# Architecture

<!-- FILL: one paragraph — what the system is, the stack, the rendering/execution model -->

<!-- This doc describes how things are *now*. For *why* a non-obvious choice
     was made, link to the relevant `docs/adr/NNNN-*.md` — don't restate its
     reasoning here. -->



## Source tree

This is the **only** home for the annotated tree. Other docs link here; none
of them restate it.

<!-- FILL:
```
src/
├── ...
└── ...
```
Annotate each entry with one line on what it owns. -->

## Request / data flow

<!-- FILL: one worked example, end to end — a typical request or job, from
     entry point through each layer to the response. This is what a new
     reader traces to understand how the pieces connect. -->

## Cross-cutting concerns

<!-- FILL: the things that span features — caching, auth/sessions, persistence,
     config, error handling. One short subsection each. Keep the detail here
     so no feature-level doc has to. -->

<!-- ===== The section below belongs only if the feature-slices half is on ===== -->

## Feature slicing

Code is organized as vertical slices under `<!-- FILL: root, e.g. src/features/ -->`,
one directory per bounded domain concept — not horizontal tech layers.
Rationale: `docs/adr/<!-- FILL: NNNN-adopt-feature-slices.md -->`.

Each slice is split into these responsibilities, named the same across every
slice so the layout is predictable to search:

<!-- FILL: the responsibility vocabulary and one line each, e.g.

- `interface` — the inbound edge (routes, CLI, handlers). Request/response only.
- `logic`     — domain rules and orchestration. No framework imports.
- `data`      — the only place that touches DB / filesystem / network.
- `types`     — the records this slice owns.
-->

Create only the responsibilities a slice actually needs. An empty file added
for symmetry is worse than an absent one. Where a responsibility exists, it
keeps the same name in every slice, so the pattern stays greppable.

### Cross-feature dependency rule

<!-- FILL: state the direction explicitly, e.g.

A slice may import another slice's `logic` or `types`. It may **never** import
another slice's `interface` or `data`. That is what keeps "vertical" meaningful:
one slice depends on another's stable surface, never its edge or its storage.
-->

If a concept is needed by many slices, promote it to a shared module — do not
add a third import chain for it.

### Known crossings

Every cross-slice import, enumerated. Kept honest by
`<!-- FILL: the enforcement hook, e.g. `scripts/check_crossings.py`, run in CI / as a test -->`.

<!-- FILL: the list, or "none yet". For each: which slice imports which, what
     it imports, and why neither side owns the concept alone. -->
