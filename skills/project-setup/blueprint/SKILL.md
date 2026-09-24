---
name: blueprint
description: >-
  Establish or retrofit a project's foundational structure — a context-documentation
  system (a single authority map, plus architecture and domain-glossary docs, an
  append-only docs/adr/ decision record, all wired into CLAUDE.md and AGENTS.md) and an
  optional vertical feature-slice code layout with an enforced cross-feature dependency
  rule. Use this whenever the user wants to set up or reorganize project documentation,
  establish AGENTS.md / CLAUDE.md, start keeping ADRs or an architecture decision record,
  introduce feature slicing or a features/<domain>/ layout, consolidate scattered or
  stale docs, decide how a codebase should be laid out, or asks where project context
  and rationale should live — for brand-new and existing projects alike.
---

# Blueprint

Lay down the structure a project's context and code sit on:

- **context-structure** — a small set of documentation files with one explicit
  authority map, so every fact has exactly one home and stays findable.
- **feature-slices** — a vertical `features/<domain>/` code layout with a
  written, enforced rule for how slices may depend on each other.

Both halves are one-shot. On a new project they scaffold; on an existing one
they migrate what is already there into the target shape. This skill does not
manage tasks, work packages, or a backlog — it only shapes context and layout.

## Step 1 — which halves

Ask with `AskUserQuestion` (multi-select, both pre-selected):

- **context-structure** — the docs system + `CLAUDE.md` / `AGENTS.md` wiring.
- **feature-slices** — the `features/<domain>/` layout + dependency rule.

Proceed only with the halves the user keeps.

## Step 2 — new or existing

Check whether the target already has docs, a `CLAUDE.md`/`AGENTS.md`, or a
source tree with real code. This decides scaffold vs migrate for each half
below. When unsure, look before asking — `ls`, read any existing `README`,
`docs/`, `CLAUDE.md`.

---

## Half A — context-structure

### The files

Templates live in `templates/`. Copy each into place, then fill the
`<!-- FILL -->` markers from the project. The load-bearing rules are already
written into the templates — don't paraphrase them away.

| File | Holds |
|---|---|
| `docs/INDEX.md` | The authority map: read order + which doc owns which topic. |
| `docs/ARCHITECTURE.md` | The source tree (its only home), request/data flow, cross-cutting concerns, and — if the feature-slices half is on — the slicing layout and dependency rule. |
| `docs/CONTEXT.md` | Domain glossary; each term names the feature that owns it. |
| `docs/adr/` | One short file per non-obvious technical choice: context → decision → consequences. Append-only, never deleted. `README.md` in it carries the format + rules + index. |
| `CLAUDE.md` | Read-order pointer + a "change type → which doc, same commit" table. |
| `AGENTS.md` | One short pointer to `CLAUDE.md`. Keeps AGENTS.md-convention tools and Claude Code on one source of truth. |

`CONTRIBUTING.md` is optional — create it only if the project wants a
"where does this code go" doc separate from `ARCHITECTURE.md`.

### The rules these files encode

State these in the files (the templates already do) and follow them when
filling content:

- **One fact, one home.** If something would fit in two docs, pick the owner
  from `INDEX.md`, put it there, and leave a pointer in the other.
- **An ADR per non-obvious technical choice.** A library swap, a data-modeling
  trade-off, a platform-quirk workaround, a deviation from the obvious
  approach — each gets one short file in `docs/adr/`. Bias toward writing
  one; the paragraph is cheap and it converts "re-read the diff and guess
  why" into "read one file." This is the single biggest lever on long-term
  context.
- **The ADR holds the *why*; state docs hold the *what*.** `ARCHITECTURE.md`
  and `CONTEXT.md` describe how things are now and link to the ADR for the
  reasoning. Neither side repeats the other, so neither goes stale against it.
- **ADRs are append-only and never deleted.** A reversed choice keeps its
  file, Status set to `Superseded by ADR-XXXX`, linking forward; the new ADR
  links back. The "tried X, then Y" trail is the value.
- **No per-directory `CLAUDE.md`.** They restate the shared docs and drift.
  One root `CLAUDE.md` plus the `docs/` tree.
- **Mechanical lists get generated or checked, not hand-curated.** Anything
  derivable from the code (an import-crossing list, a route table) should
  have a script or test backing it — hand-maintained lists rot silently.

### New project

Create all files, fill what you can from the code and a short interview
(project name, one-line description, the domains, the main flow). Leave the
glossary near-empty. `docs/adr/` ships with `README.md` and
`0001-adopt-blueprint-structure.md` (dated) — that's the only ADR to start.
If the feature-slices half is on, also write `0002` recording the
slices-not-layers choice.

### Existing project

This is a migration, not a drop-in. Work in this order:

1. **Inventory.** List every doc that exists — `README`, `docs/*`, `CLAUDE.md`,
   `AGENTS.md`, stray `NOTES.md`/`ARCHITECTURE` files, design notes in the
   wiki if mentioned.
2. **Map into slots.** For each existing piece of prose, decide which target
   doc owns it. Move it; leave a pointer where it was. Never delete content
   you can't place — flag it for the user.
3. **Deduplicate.** Where the same fact appears twice, keep the copy in the
   owner doc and cut the rest to pointers.
4. **Backfill lightly.** Draft the glossary from domain terms in the code and
   a short interview. Don't reconstruct a decision history — start `docs/adr/`
   at `0001` (adopt structure). If the project already has an ADR log or a
   `DECISIONS.md`, keep those files as historical `00xx` ADRs (or an
   `adr/legacy-decisions.md`) rather than rewriting them.
5. **Report** what moved, what was merged, and what you couldn't classify.

---

## Half B — feature-slices

A generic pattern; the project chooses the concrete vocabulary once.

### The pattern

- **`<root>/<domain>/`** — one directory per bounded domain concept, not per
  tech layer. No repo-wide `routers/`, `models/`, `store/`.
- Each slice is split into **responsibilities named identically across every
  slice**, so the layout is predictable to grep. The project picks that
  vocabulary — e.g. `interface / logic / data / types`, or
  `handler / core / store / schema`, or whatever fits the stack.
- **Create only the responsibilities a slice needs.** An empty file for
  symmetry is worse than an absent one.
- **One declared cross-slice dependency rule.** Some responsibility layers may
  be imported by other slices; others never may be. The project states the
  direction explicitly (typically: depend on another slice's stable/abstract
  layers, never its edges or its storage). The invariant is that the rule is
  written down, in `ARCHITECTURE.md`.
- **Known crossings list.** Every cross-slice import, enumerated in
  `ARCHITECTURE.md`, kept honest by an enforcement hook (see
  `scripts/check_crossings.py` for a starting point to adapt).
- **Shared concept → shared module.** When a third slice needs the same
  crossing two others already share, that's the signal to promote it to a
  shared module, not to add a third import chain.

### Ask the project once

- **Root** — `src/features/`, `internal/`, `app/`, `packages/`, …
- **Responsibility vocabulary** — the identical-across-slices layer names.
- **Which layers cross** — the importable set vs the never-imported set.
- **Enforcement hook** — a task recipe, a test, or a lint rule that runs the
  crossings check.

Then write the "Feature slicing" and "Cross-feature dependency rule" sections
into `ARCHITECTURE.md` (the template has the shell), and drop the adapted
check script into place wired to the chosen hook.

### New project

Create the root, one example slice showing the full vocabulary, and the
`ARCHITECTURE.md` sections. The example slice is documentation — keep it
minimal or delete it once real slices exist.

### Existing project

**Not a scaffold — a multi-step refactor the user drives.** Do:

1. **Detect the current layout** — horizontal layers, flat, partly sliced?
2. **Write the target** — the vocabulary, the rule, the `ARCHITECTURE.md`
   sections — so there's something concrete to move toward.
3. **Produce a per-slice migration checklist** — which existing files become
   which slice's which responsibility, and which cross-imports will violate
   the new rule and need a shared module.
4. **Record the choice.** Write an ADR for adopting feature slices — the
   context (what the layout was, why it hurt), the decision, the
   consequences (the migration is incremental, the rule is enforced by the
   check script).
5. **Stop there.** Moving the code is the user's follow-up, slice by slice.
   Say this plainly; don't start relocating modules wholesale.

---

## Anti-staleness (why the structure is shaped this way)

Staleness enters when one file carries two things with different lifecycles:
an immutable record ("why we chose this, then") and current-state knowledge
("what the system is now"). Mix them and "now" scatters across dated entries;
reversals leave both versions live.

The structure separates them:

- **Current state** lives in `ARCHITECTURE.md` / `CONTEXT.md` — small, always
  current, drift visible in a diff. They link out for reasoning.
- **Reasoning** lives in `docs/adr/` — one immutable file per choice, context
  → decision → consequences, superseded-and-linked never rewritten. A reader
  chasing "why" reads one file, not a diff and a hunch.
- The `CLAUDE.md` "same commit" table makes the doc update a gate, not a
  follow-up — the deferred follow-up is where drift got in.
- Mechanical lists (the crossings list) are checked by a script, because
  humans forget to update them.

Keep these properties when filling the templates. The failure modes to avoid:
an ADR that tries to stay current with the code (it shouldn't — it's a
snapshot of a decision), and a state doc that re-explains a rationale instead
of linking the ADR.

## Templates and scripts

- `templates/` — one file per target doc (`INDEX.md`, `ARCHITECTURE.md`,
  `CONTEXT.md`, `CLAUDE.md`, `AGENTS.md`). Copy, then fill `<!-- FILL -->`.
- `templates/adr/` — `README.md` (format + rules + index) and
  `0001-adopt-blueprint-structure.md` (the seed ADR). Copy the directory in
  whole.
- `scripts/check_crossings.py` — example cross-slice import checker. It is a
  starting point: adapt the layer names and import syntax to the project,
  then wire it to the chosen enforcement hook.
