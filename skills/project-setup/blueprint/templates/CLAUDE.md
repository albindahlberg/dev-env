# <!-- FILL: project name -->

<!-- FILL: one-line description of the project -->

## Reading order

Start with `docs/INDEX.md` — it is the authority map for every other doc.
Then `CONTRIBUTING.md` (if present), `docs/ARCHITECTURE.md`, `docs/CONTEXT.md`.

## Keeping docs in sync

One fact has one home. When a change touches one of these, update the named
doc **in the same commit** — a deferred doc update is where staleness gets in:

| When a change touches… | Update, same commit |
|---|---|
| request/data flow, the source tree, a cross-cutting concern | `docs/ARCHITECTURE.md` |
| a domain term, or which feature owns it | `docs/CONTEXT.md` |
| a non-obvious technical choice (library swap, data-modeling trade-off, platform workaround) | `docs/adr/` — add `NNNN-short-title.md` |

An ADR holds the *why*; the current-state docs link to it and don't restate
it. Never rewrite a shipped ADR — supersede it with a new one and link
forward. See `docs/adr/README.md`.

Do not create per-directory `CLAUDE.md` files — they restate the docs above
and drift out of sync. One root `CLAUDE.md` plus the `docs/` tree.

<!-- ===== The section below belongs only if the feature-slices half is on ===== -->

## Feature slices

Code is vertical slices under `<!-- FILL: root -->`. The layout and the
cross-feature dependency rule live in `docs/ARCHITECTURE.md` ("Feature
slicing"). Before adding an import from one slice to another, check it against
"Known crossings" there — and never import another slice's
`<!-- FILL: the never-imported layers -->`.
