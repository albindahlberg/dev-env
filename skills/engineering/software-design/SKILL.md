---
name: software-design
description: Minimise complexity with deep modules, information hiding and the book's red flags (A Philosophy of Software Design). Use when planning a new or changed interface, adding a feature, module, or file, deciding where code belongs, calling across modules, or reviewing a change for complexity.
---

# Software design

A module hides a set of design decisions behind a small public interface.
Callers learn the interface; everything else is private and free to change.
The interface is the cost, the hidden functionality the benefit, and a simple
interface matters more than a simple implementation.

Complexity is whatever makes the code hard to understand and change, judged
by the next reader and weighted by how often people touch that part. It shows
up as change amplification, cognitive load and unknown unknowns, and it comes
from dependencies and obscurity. It grows one tactical shortcut at a time, so
work strategically: every change keeps each module's interface or deliberately
moves it, and spends a little extra on design to do so.

Vocabulary (depth, adapter, leverage, locality, deletion test) lives in
`mattpocock-skills:codebase-design`. This skill is the layout, the rules
that keep it, and the [red flags](RED-FLAGS.md) that show where it slipped.

Pick the branch for the work in hand:

- **Planning** a change before code exists → [Planning](#planning).
- **Building** → [Steps](#steps).
- **Reviewing** a diff, branch or PR → [Review](#review).

## Planning

Planning is where strategic design is cheapest: an interface fixed here is
an issue edit, the same fix after build is a refactor. A plan pins the
interface and leaves the implementation to the builder.

1. **Find the owner** of each piece of knowledge the change touches, per
   [Steps](#steps) 1–2 and [Placement](#placement).
2. **Check the ground.** Run the design-level flags (shallow module,
   information leakage, temporal decomposition, overexposure, pass-through,
   special-general mixture, conjoined methods) and the co-change history
   from [RED-FLAGS.md](RED-FLAGS.md) on the modules the change lands in.
   Done when each touched module is judged fit to build on, or has a
   prefactor that goes first.
3. **Design it twice** for every public interface the plan adds or changes.
   A first idea is rarely the best, and one mind sketching alternatives
   produces variations of it, so the designs come from separate subagents:
   - Write a short technical brief: the constraints any interface must
     meet, the dependencies behind the interface, the files involved, and the
     `CONTEXT.md` terms to name things by.
   - Spawn 3+ `general-purpose` subagents in parallel, one message, each
     with the brief and a different constraint: minimise the interface
     (1–3 entry points); maximise flexibility; make the most common call
     trivial; and, when a dependency crosses the interface, ports and adapters.
     Each returns the interface (types, invariants, ordering, error
     modes), one call site, what it hides behind the interface, and where its
     leverage is high or thin.
   - Compare them by depth (leverage at the interface), locality (where
     change concentrates), where the interface sits, and which design-level flags
     each trips. Generality is sized to what the plan says comes next, not
     to anything that might.
   - Show them side by side via `show-me` with an opinionated
     recommendation, a hybrid when parts combine well.
4. **Pin the winner** as the slice's interface: the owning module, the
   signatures with one call site, the types crossing the interface, invariants
   and ordering, error modes, and which module absorbs each hard case
   (retries, idempotency, partial failure). Name the interfaces tests go
   through, as few and as high as possible, each with what it catches.
   Write one sentence describing it from the caller's side; a sentence
   that needs "and" or caveats sends it back to step 3. A new layer's
   interface differs from the one below it, or the layer goes.

Done when every added or changed interface is pinned and the reason it
beats each alternative is written down: an ADR when the plan records them
(as in `spec`), otherwise the reply.

## Steps

When the work comes with a pinned interface (a spec's `## Interface`),
build behind it exactly; one that turns out wrong goes back to the plan
rather than being redrawn mid-build.

1. **Match the repo.** Read its AGENTS.md / CLAUDE.md, ADRs and any
   `.importlinter` or eslint boundaries config. A module convention already
   in place wins over this skill; apply the rest only where the repo has
   none.
2. **Find the owner.** For the change in hand, name the module that owns the
   knowledge it touches, and read that module's public interface. Done when
   you can say which existing public function the change calls, extends, or
   which new one it adds, and in which module.
3. **Reuse the public interface.** Call the owner's public functions and
   types. When the need is an internal of another module, pick one move from
   [Sharing](#sharing) and say which in the reply.
4. **Place the code** by the [Placement](#placement) rules and the
   [Module structure](#module-structure).
5. **Check the change** against the [Self-check](#self-check) and every
   flag in [RED-FLAGS.md](RED-FLAGS.md). Every question answered and every
   flag checked; a hit is fixed or called out in the reply.

The change touches background jobs, events, persistence, transactions or a
capability module →
also read [PATTERNS.md](PATTERNS.md).

## Placement

- **Split by knowledge.** A module owns one set of decisions and the data
  behind them, and holds everything that changes when those decisions do:
  send, edit and delete share what a message is, so they live in one
  `messages` module. Each shape has one owner; every other place imports or
  generates it.
- **Depth is measured at the public surface.** Inside, layer as much as
  helps (rules → persistence); only what callers import counts.
- **Intent-shaped interfaces.** Public functions name what the caller wants
  (`add_member()`, `send()`, `rename()`) and enforce the module's own rules,
  so every caller gets them for free.
- **Make the safe path the only path.** Security and correctness inputs
  (`scope`, `ctx`, the acting user) are required parameters.
- **Define errors out of existence.** Idempotent writes (a `client_id`),
  no-op deletes, leases and `greatest()` updates turn would-be errors into
  normal outcomes.
- **Somewhat general-purpose.** Shape each signature for the general
  mechanism, not today's one use (`insert(pos, text)`, not `backspace()`).
  Ask what the simplest interface covering every current need is, how many
  situations will call it, and whether it is still easy for today's call.
  This shapes one signature; adding abstractions is the separate rule below.
- **Decide inside the module.** The module picks the sensible behaviour
  itself, so its interface stays as small as its callers' real choices.
- **Pull complexity down.** A hard problem (retries, idempotency, scoping)
  is solved once in the lowest module that can own it, so callers stay
  simple.
- **Every wrapper adds rules or orchestration.** When a function would only
  forward, callers use the inner one directly.
- **Ready-made instances.** A class-based module exposes one built instance
  (`Messages.default()`) and keeps its wiring private, since constructor
  args are interface too.
- **Abstractions follow real variation.** A protocol, factory or event arrives
  with the second implementation or consumer; until then the module is one
  plain implementation.

### Layers

Dependencies point down and the import graph stays a DAG.

```
Adapters      translate only        HTTP routes, CLI, worker entrypoints, frontend data layer
Domain        own data + intent     one module per area of knowledge
Capabilities  content-agnostic      attachments, search, tools
Platform      domain-free           db, queue, events, storage, llm
Contracts     shapes only           event and wire types shared across modules
```

- Platform depends only on platform and third-party code.
- An adapter makes one module call per write. Composing reads for one screen
  is presentation and fits there; write workflows live in the owning
  module, or a small use-case module (`onboarding.register()`) when no
  module owns them.
- A worker is one more adapter into the same modules.
- A capability takes opaque refs (`"message:8f3a"`) and stores them as-is.
  Sources call it and it depends on none of them; a caller resolves a ref
  through the owning module, which re-checks permissions. Scope is applied
  inside the query.
- Each layer hides distinct knowledge (HTTP, transport, broker).

## Module structure

Each module is a directory with a public face and a private inside.

- **Public**: one entry file (`__init__.py`, `index.ts`) exposing the
  module's functions, plus the frozen value types that cross the interface.
  This is everything callers import.
- **Private**: everything else, under plain names. The interface comes from
  the entry file and the [Enforcement](#enforcement) contract, not from
  filenames; when a visible marker helps, put internals in one `_internal/`
  subpackage. A repo already using `_name.py` keeps it. Typically the rules and orchestration
  that own the transaction, persistence that returns domain types, handlers
  for jobs and events, and one file per piece of module knowledge.
- Every module follows the same layout and names, so a reader who knows one
  knows where things are in all of them. A repo that already has a layout
  keeps it; a new one picks names once and reuses them.
- Each file holds one piece of knowledge and is named for it (`rank.py`,
  `provider.py`). It appears when that knowledge does and grows into a
  subpackage of the same name.
- The module's tables or collections carry its prefix (`msg_`, `doc_`), and
  only that module queries them.
- Vendors (LLM, STT, S3, MCP) sit behind one private adapter or a platform
  module, so a vendor swap is one file.
- Tests exercise the public interface.
- Contracts have one source of truth, generated outward: server schema →
  OpenAPI → client types.

## Sharing

Cross-module code goes through public functions and public frozen types.
When another module's internal looks useful, choose one:

- **Promote** it to the owner's public interface, deliberately named.
- **Push it down** to platform when it is domain-free.
- **Merge** the two modules when they share the knowledge anyway.

## Enforcement

For a new repo, or one that adopts this layout, add the checks that keep it:

- Python: `import-linter` contracts that allow cross-module imports only
  from a module's package root (`from app.messages import send`) and keep
  platform independent of modules.
- TypeScript: `eslint-plugin-boundaries`, with features importing only the
  data module and UI components.

## Self-check

Layout checks for this skill's module structure; the book's red flags live
in [RED-FLAGS.md](RED-FLAGS.md). Each question names what to look for and
the fix.

1. **Logic in an adapter**: could a worker or CLI reuse each rule? Move
   rules from routes into the owning module.
2. **Cross-module imports**: is the import graph a DAG with only public imports
   across modules? Promote, push down or merge per [Sharing](#sharing).
3. **Optional safety**: are scope and ctx required and handlers idempotent?
4. **Leaked internals**: do callers see only domain types? Convert ORM rows,
   column names and queue fields at the interface.
5. **Classitis**: does every protocol, factory and event have a second
   implementation or consumer behind it?

## Review

A review runs in fresh context, so it judges the code rather than the
reasoning that produced it.

1. **Scope** the diff: the target given (PR, branch, path), else
   `git diff <base>...HEAD` against the merge base.
2. **Dispatch** one `general-purpose` subagent with only the diff target,
   the repo path and this skill's directory. Leave out the builder's plan
   and reasoning; when the work has a spec issue, include its number. Tell
   it to read `SKILL.md` and `RED-FLAGS.md`, run the Self-check and every
   flag against every changed module and its callers, and return each hit
   as: flag, `file:line`, mechanical or judgement, the fix. With a spec
   issue it also checks the code matches `## Interface` (a mismatch is a
   hit to fix, citing the interface element) and that each requirement ID and acceptance criterion is
   met (an unmet one is a hit to fix, citing its ID). Done when every
   flag, and with a spec every interface element and requirement ID, is
   marked hit or clear.
3. **Report** the hits, mechanical first. Posted to a PR, they follow
   `conventional-comments`.
