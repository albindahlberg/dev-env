---
name: software-design
description: Minimise complexity with deep modules, information hiding and the red flags from A Philosophy of Software Design. Use when planning a new or changed interface, adding a feature, module, or file, deciding where code belongs, calling across modules, or reviewing a change for complexity.
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

This skill is the principles and the [red flags](RED-FLAGS.md) that show
where they slipped. It prescribes no layout: the repo's own structure and
names stay.

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
     glossary terms to name things by.
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
   (retries, idempotency, partial failure). Name every public element per
   [NAMING.md](NAMING.md)'s Choosing a public name. Name the interfaces tests go
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
4. **Place the code** by the [Placement](#placement) rules.
5. **Check the change** against every flag in [RED-FLAGS.md](RED-FLAGS.md)
   and [NAMING.md](NAMING.md). Done when every flag is checked; a hit is
   fixed or called out in the reply.

## Placement

- **Split by knowledge.** A module owns one set of decisions and the data
  behind them, and holds everything that changes when those decisions do:
  send, edit and delete share what a message is, so they live in one
  module. Each shape has one owner; every other place imports or generates
  it.
- **One public entry.** Callers import a module through its public entry
  (`__init__.py`, `index.ts`, or the repo's equivalent); everything else
  is private and free to change.
- **Depth is measured at the public interface.** Inside, layer as much as
  helps; only what callers import counts.
- **Intent-shaped interfaces.** Public functions name what the caller wants
  (`add_member()`, `send()`, `rename()`) and enforce the module's own rules,
  so every caller gets them for free.
- **Make the safe path the only path.** Security and correctness inputs
  (the scope, the acting user) are required parameters.
- **Define errors out of existence.** Idempotent writes and no-op deletes
  turn would-be errors into normal outcomes.
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
- **Abstractions follow real variation.** A protocol, factory or event arrives
  with the second implementation or consumer; until then the module is one
  plain implementation.
- **Dependencies point one way.** The import graph stays acyclic, and
  general-purpose modules never import the modules that use them.
- **Callers see domain types.** Database rows, vendor payloads and
  transport shapes are converted at the interface of the module that owns
  them, so a vendor or schema swap stays inside it.
- **Rules live below the entry points.** A route, CLI command or worker
  translates its input and makes one call; the rule sits in the owning
  module, where every entry point reuses it.
- **Tests exercise the public interface.**

## Sharing

Cross-module code goes through public functions and public types. When
another module's internal looks useful, choose one:

- **Promote** it to the owner's public interface, deliberately named.
- **Push it down** to a lower-level shared module when it carries no
  knowledge of its callers.
- **Merge** the two modules when they share the knowledge anyway.

## Review

A review runs in fresh context, so it judges the code rather than the
reasoning that produced it.

1. **Scope** the diff: the target given (PR, branch, path), else
   `git diff <base>...HEAD` against the merge base.
2. **Dispatch** one `general-purpose` subagent with only the diff target,
   the repo path and this skill's directory. Leave out the builder's plan
   and reasoning; when the work has a spec issue, include its number. Tell
   it to read `SKILL.md`, `RED-FLAGS.md` and `NAMING.md`, run every
   flag against every changed module and its callers, and return each hit
   as: flag, `file:line`, mechanical or judgement, the fix. With a spec
   issue it also checks the code matches `## Interface` (a mismatch is a
   hit to fix, citing the interface element) and that each requirement ID is
   met (an unmet one is a hit to fix, citing its ID). Done when every
   flag, and with a spec every interface element and requirement ID, is
   marked hit or clear.
3. **Report** the hits, mechanical first. Posted to a PR, they follow
   `conventional-comments`.
