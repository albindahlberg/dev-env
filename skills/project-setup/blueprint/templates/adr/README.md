# Architecture Decision Records

One file per non-obvious technical choice — a library swap, a data-modeling
trade-off, a workaround for a platform quirk, a deviation from the approach a
reader would expect. If someone would otherwise have to re-read the diff and
guess *why*, it gets an ADR.

This is the project's primary decision record. Bias toward writing one: a
thirty-second paragraph now turns "read the commit history and reconstruct
the reasoning" into "read one file."

## Format

`docs/adr/NNNN-short-title.md` — four-digit number, next in sequence. Keep it
short; most ADRs are five to fifteen lines.

~~~
# ADR-NNNN: <title>

- **Date:** YYYY-MM-DD
- **Status:** Accepted        <!-- Proposed | Accepted | Superseded by ADR-XXXX -->

## Context
What forced a choice — the constraint, the quirk, the options in tension.

## Decision
What was chosen. One or two sentences.

## Consequences
What this makes easy, what it makes hard, what a reader should watch for.
~~~

## Rules

- **Append-only.** Once an ADR is Accepted, don't rewrite its Context or
  Decision. New information becomes a new ADR.
- **Never delete.** A reversed choice stays on record: set its Status to
  `Superseded by ADR-XXXX` and link forward to the replacement; the new ADR
  links back in its Context. The "we tried X, then moved to Y" trail is the
  value.
- **One home for the *why*.** `ARCHITECTURE.md` and `CONTEXT.md` describe the
  current state and link to the ADR for the reasoning — they don't repeat it,
  and the ADR doesn't try to track their later changes.

## Index

Newest first.

<!-- FILL:
| # | Title | Date | Status |
|---|---|---|---|
| 0001 | Adopt the blueprint documentation structure | YYYY-MM-DD | Accepted |
-->
