---
name: software-design
description: Design for locality with deep modules and the red flags from A Philosophy of Software Design. Use when planning a new or changed interface, adding a feature, module, or file, deciding where code belongs, calling across modules, or reviewing a change for complexity.
---

# Software design

Complexity is whatever makes code hard to understand and change, judged by
the next reader and weighted by how often that part is touched. It grows one
tactical shortcut at a time, so work strategically: every change keeps each
module's interface or deliberately moves it, and spends a little extra on
design to do so.

## Glossary

Use these terms exactly; each names one thing.

- **Module**: anything with an interface and an implementation: a
  function, a class, a file of functions, a package.
- **Interface**: everything a caller must know to use a module: signatures,
  types, invariants, ordering, error modes. Callers learn it; everything
  else is private and free to change.
- **Concern**: what a module does for its callers, stated from their side
  in one sentence ("owns how files reach the bucket"). Each module owns one
  concern. _Avoid_ for this: behaviour, knowledge, decisions, responsibility, secret.
- **Owner**: the module that owns a concern. Each concern has one.
- **Deep**: a small interface over a lot of functionality. **Shallow**: an
  interface about as complex as what sits behind it.
- **Locality**: a change to a concern lands in its owner alone. The goal
  every rule here serves.
- **Leak**: a concern's details (a format, a constant, a call order, a
  rule) known outside its owner, so a change to it lands there too.
- **The change test**: name the likely changes to a concern (from the
  spec, the intent's later items, the repo's history). Each touches only
  the owner; one that touches more means the concern leaked or was split
  too fine.
- **The deletion test**: imagine deleting a module. If the complexity
  vanishes, it was a pass-through: merge it into its caller or neighbour.
  If it reappears across its callers, it earns its place.

This skill prescribes no layout: the repo's own structure and names stay.
Pick the branch for the work in hand:

- **Planning** a change before code exists → [PLANNING.md](PLANNING.md).
- **Building** → [Steps](#steps) and [Placement](#placement) below.
- **Reviewing** a diff, branch or PR → [REVIEW.md](REVIEW.md).

## Steps

When the work comes with a pinned interface (a spec's `## Interface`),
build behind it exactly; one that turns out wrong goes back to the plan
rather than being redrawn mid-build.

1. **Match the repo.** Read its AGENTS.md / CLAUDE.md, ADRs and any
   `.importlinter` or eslint boundaries config. A module convention already
   in place wins over this skill; apply the rest only where the repo has
   none. Adding or tightening boundary lint is the user's call: propose
   the contract in the reply.
2. **Find the owner.** For the change in hand, name the owner of the
   concern it touches, and read that module's public interface. Done when
   you can state the owner's concern in one sentence and say which
   existing public function the change calls, extends, or which new one
   it adds, and in which module. Work that makes a caller know how the
   owner does its job leaks the concern: move it into the owner. A new
   module that fails the deletion test merges into its neighbour.
3. **Reuse the public interface.** Call the owner's public functions and
   types. When the need is an internal of another module, pick one move from
   [Sharing](#sharing) and say which in the reply.
4. **Place the code** by the [Placement](#placement) rules.
5. **Check the change.** Run the change test and the deletion test on
   every module you touched or added, and name each new public element
   per [NAMING.md](NAMING.md)'s Choosing a public name. Done when each
   module passes both tests or the miss is called out in the reply. The
   full [red flags](RED-FLAGS.md) are the review's job.

## Placement

- **Split by concern.** Send, edit and delete share what a message is,
  so they live in one module. Each data shape has one owner; every other
  place imports or generates it.
- **One public entry.** Callers import a module through its public entry
  (`__init__.py`, `index.ts`, or the repo's equivalent); everything else
  is private and free to change.
- **Intent-shaped interfaces.** Public functions name what the caller wants
  (`add_member()`, `send()`, `rename()`) and enforce the module's own rules,
  so every caller gets them for free.
- **Make the safe path the only path.** Security and correctness inputs
  (the scope, the acting user) are required parameters.
- **Define errors out of existence.** Idempotent writes and no-op deletes
  turn would-be errors into normal outcomes.
- **Somewhat general-purpose.** Shape each signature for the general
  mechanism, not today's one use (`insert(pos, text)`, not `backspace()`),
  while keeping today's call easy.
- **Decide inside the module.** The module picks sensible defaults
  itself, so its interface stays as small as its callers' real choices.
- **Pull complexity down.** A hard problem (retries, idempotency, scoping)
  is solved once in the lowest module that can own it, so callers stay
  simple.
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
- **Push it down** to a lower-level shared module when it knows nothing
  of its callers.
- **Merge** the two modules when they own one concern between them.

