# Documentation Index

Navigation and authority map for this project's docs. When two docs touch the
same topic, the one named here as owner wins — prefer it, and cut the other
copy to a pointer.

## Read order

1. `README.md` — setup, prerequisites, day-one commands
<!-- FILL: keep the next line only if CONTRIBUTING.md exists -->
2. `CONTRIBUTING.md` — where new code goes
3. `docs/ARCHITECTURE.md` — layers, request/data flow, cross-cutting behavior
4. `docs/CONTEXT.md` — domain glossary and ownership
5. `docs/adr/` — why non-obvious technical choices were made (one short file each)

## Topic owners

| Topic | Owner |
|---|---|
| Setup / local run | `README.md` |
| Where code belongs | `CONTRIBUTING.md` <!-- or ARCHITECTURE.md if no CONTRIBUTING --> |
| Architecture, layering, request/data flow, the source tree | `docs/ARCHITECTURE.md` |
| Domain terms, which feature owns each | `docs/CONTEXT.md` |
| Why a non-obvious choice was made | `docs/adr/` (one file per decision) |
<!-- FILL: add project-specific topics and their owners -->

If a fact appears in two docs, delete one copy and leave a pointer to the
owner. One fact, one home — that is the whole point of this file.
