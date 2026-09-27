---
name: spec
description: 'Turn an intent issue into spec sub-issues: read the intent and the codebase, grill the user on flagged concerns and open design decisions (recording ADRs and glossary terms), then write the spec and file each shippable slice as a sub-issue ready for `build`. Stage 2 (Design) of the AI-native SDLC. Trigger: "spec", "spec #12", "write the spec for", or /spec.'
---

# Spec

Stage 2 of intent -> spec -> build. Input: an intent issue number (from the
`intent` skill). Output: one or more sub-issues under it, each implementable
by `build`.

1. **Research** - before asking anything, read the intent
   (`gh issue view N --comments`), `CLAUDE.md` / `AGENTS.md`, `CONTEXT.md`,
   existing ADRs, and the code the change touches (sub-agents for broad
   sweeps). Don't write the spec yet; list:
   - **Flagged concerns** - conflicts with the intent's constraints, repo
     conventions, security, or existing ADRs; plus risky or ambiguous calls.
   - **Open decisions** - where it lands in the codebase, interfaces, data
     flow, how to slice it, each with your recommended answer.

2. **Grill** - call the Skill tool for `skewer-w-docs` (grilling via the
   AskUserQuestion picker + ADRs and glossary). Seed the design tree with
   the flagged concerns first, then the open decisions; your research
   supplies each question's recommended option. Record each resolved
   decision that meets domain-modeling's ADR bar as an ADR, and new terms
   in `CONTEXT.md`, as you go, not at the end. Any answer that changes the
   intent (new problem, dropped outcome) goes back to the intent issue as a
   comment rather than being silently absorbed.

3. **Write** - once the tree is empty, write the spec from the settled
   decisions:
   - **Requirements** - each traces to a line of the intent.
   - **Design** - as decided in the grill.
   - **Slices** - small incremental changes, one PR each, that together
     form one PR stack closing the intent. Each must be coherent and green
     on its own, not necessarily user-visible. Put them in one linear
     order: foundations first, dependents after what they need, riskier
     independent slices lower so they're reviewed early. One slice is
     fine for a small change.

   Add visuals where they beat prose: call the Skill tool for `show-me`
   and pick its smallest fitting shape - flow or sequence for data flow,
   a `diff` on the call/file tree for where it lands, a table for
   compared options. In chat, render per `show-me`; in the issue body use
   the Mermaid source (GitHub renders it). Show it, slice order included,
   and wait for an explicit yes.

4. **File** - one sub-issue per slice, in stack order:
   `gh issue create --parent N`, writing per the `issue` skill, title
   the slice with no prefix, label `spec` (create it if missing), body:

   ```md
   Intent: #N
   Stack: 2/4, after #a     <!-- first slice: "Stack: 1/4, base main" -->

   ## Requirements
   ## Design
   ## Acceptance criteria
   ## Decisions        <!-- ADR links, resolved concerns -->
   ## Out of scope     <!-- drop if empty -->
   ```

   Commit the ADR / `CONTEXT.md` changes (per `commit`) and link them in
   the relevant sub-issues. Add the repo's **ready** label (per the `issue`
   skill's label discovery, e.g. `agent:ready` / `agent-ready`) to the
   intent, not the sub-issues, so `build` picks up the whole stack. None
   exists: create `agent:ready` and use it.

5. **Hand off** - list the sub-issue links in stack order; the next step is
   `/build #N` (the intent).
