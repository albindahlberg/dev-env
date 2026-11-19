# Planning

Planning is where strategic design is cheapest: an interface fixed here is
an issue edit, the same fix after build is a refactor. A plan pins the
interface and leaves the implementation to the builder.

1. **Find the owner** of each concern the change touches, per
   [SKILL.md](SKILL.md)'s Steps 1–2 and Placement.
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
     glossary terms to name things by (the repo's and
     [SKILL.md](SKILL.md)'s).
   - Spawn 3+ `general-purpose` subagents in parallel, one message, each
     with the brief and a different constraint: minimise the interface
     (1–3 entry points); maximise flexibility; make the most common call
     trivial; and, when a dependency crosses the interface, ports and adapters.
     Each returns the interface (types, invariants, ordering, error
     modes), one call site, the concern it owns, and where its
     leverage is high or thin.
   - Compare them by depth, locality, where the interface sits, and which design-level flags
     each trips. Generality is sized to what the plan says comes next, not
     to anything that might.
   - Show them side by side via `show-me` with an opinionated
     recommendation, a hybrid when parts combine well.
4. **Pin the winner** as the slice's interface: the owning module, the
   concern it owns in one sentence and its allowed importers, the
   signatures with one call site, the types crossing the interface,
   invariants and ordering, error modes, and which module absorbs each hard case
   (retries, idempotency, partial failure). Name every public element per
   [NAMING.md](NAMING.md)'s Choosing a public name. Name the interfaces tests go
   through, as few and as high as possible, each with what it catches.
   Write one sentence describing it from the caller's side; a sentence
   that needs "and" or caveats sends it back to step 3. A new layer's
   interface differs from the one below it, or the layer goes. A module
   the slice changes only inside still gets its concern pinned, so the
   change test runs on it too.

Done when every added or changed interface is pinned and the reason it
beats each alternative is written down: an ADR when the plan records them
(as in `spec`), otherwise the reply.
