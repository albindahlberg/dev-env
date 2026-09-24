# ADR-0001: Adopt the blueprint documentation structure

- **Date:** <!-- FILL: YYYY-MM-DD -->
- **Status:** Accepted

## Context

The project needs a durable home for context that doesn't go stale as the
code moves. Scattered notes and "ask whoever wrote it" don't survive
contributor turnover or a long gap between sessions, and reconstructing the
reasoning behind a past choice from the diff is slow and unreliable.

## Decision

Adopt `docs/INDEX.md` as the authority map, with `docs/ARCHITECTURE.md` and
`docs/CONTEXT.md` as the current-state docs it names, and `docs/adr/` as the
append-only decision record. Wire the read order and the "change type → which
doc" table into `CLAUDE.md`; `AGENTS.md` points at `CLAUDE.md`.

## Consequences

Every non-obvious technical choice from here on gets a short ADR. Current-state
docs link to ADRs for rationale instead of restating it. One fact, one home;
the reasoning trail is never rewritten, only superseded and linked forward.
