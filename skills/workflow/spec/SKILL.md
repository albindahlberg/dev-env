---
name: spec
description: 'Turn an intent issue into spec sub-issues: read the intent and the codebase, grill the user on flagged concerns and open design decisions (recording ADRs and glossary terms), then write the spec and file each shippable slice as a sub-issue ready for `build`. Stage 2 (Design) of the AI-native SDLC. Trigger: "spec", "spec #12", "write the spec for", or /spec.'
---

# Spec

Stage 2 of intent -> spec -> build. Input: an intent issue number (from the
`intent` skill). Output: one or more sub-issues under it, each ready for
`build`.

A spec is strategic: it delivers the intent and leaves the design better
for the next change. It pins every module interface the change adds or changes,
so a fresh agent with only the sub-issue can build it without making a
design decision, and leaves each module's implementation to `build`.

1. **Research** - before asking anything, read the intent
   (`gh issue view N --comments`), `CLAUDE.md` / `AGENTS.md`, `CONTEXT.md`,
   existing ADRs, and the code the change touches (sub-agents for broad
   sweeps). Run `software-design`'s Planning steps 1–2 (owner, ground
   check). List, for the grill:
   - **Flagged concerns** - conflicts with the intent's constraints, repo
     conventions, security, or existing ADRs; plus risky or ambiguous calls.
   - **Design health** - each touched module judged fit to build on, or
     the prefactor it needs first, with the red flags and co-change evidence.
   - **Open decisions** - which module interfaces the change adds or
     changes, which module owns each, data flow, how to slice it, each
     with your recommended answer.

   Done when every touched module has a design-health verdict and every
   open decision a recommended answer.

2. **Grill** - first create the decisions worktree:
   `git worktree add <dir> -b docs/intent-N-decisions`, N the intent's
   issue number, `<dir>` named per `worktree`. Every ADR and `CONTEXT.md`
   edit from here on is written in that worktree. Then call the Skill tool for `skewer-w-docs` (grilling via the
   AskUserQuestion picker + ADRs and glossary). Seed the design tree
   strategic first, so the shape is settled before the work is cut up:
   1. **Flagged concerns.**
   2. **Design health** - per touched module: build on it as is, or a
      prefactor slice first.
   3. **Investment** - how much of this stack improves the design versus
      delivering the outcome, judged against the intent's known pain and
      **later** items.
   4. **Module interfaces** - once 1–3 are settled, run
      `software-design`'s Planning step 3 for each added or changed
      interface; each sketch set is one
      question. Before asking it, call the Skill tool for `show-me` and
      open its Markdown preview with one section per option: the
      interface, one call site, what it hides, and the module shape
      before and after as Mermaid, with your recommendation on top. The
      user reads the preview and answers in the picker. Re-run the
      preview as answers land so it always shows the current design;
      then the pinned interface per Planning step 4.
   5. **Slicing and the rest.**

   Your research supplies each question's recommended option. Record each
   resolved decision that meets domain-modeling's ADR bar as an ADR, and
   rejected interface alternatives below that bar in the slice's
   `## Decisions`; new terms go in
   `CONTEXT.md` (domain-modeling's glossary format, but always this
   file), as you go, not at the end. Any answer that changes the
   intent (new problem, dropped or narrowed outcome) is a scope change:
   edit it into the intent body per the `issue` skill.

3. **Write** - once the tree is empty, write the spec from the settled
   decisions:
   - **Requirements** - numbered `R1`, `R2`, ... across the intent, each
     tracing to a line of the intent and stated so it can be checked.
     Slices, acceptance criteria and reviews cite them by ID. Each of the
     intent's open questions is answered here or carried forward as one.
   - **Design** - as decided in the grill.
   - **Interface** - per slice, the owning module, its pinned interface and the
     interfaces tests go through, from
     `software-design`'s Planning step 4.
   - **Slices** - small incremental changes, one PR each, that together
     form one PR stack closing the intent. Each must be coherent and green
     on its own, and lists the requirement IDs it delivers; every ID lands
     in some slice. Prefer vertical slices, a narrow path through every
     layer that can be verified on its own, so each interface is reviewed
     with its caller. A wide mechanical refactor goes expand–contract
     instead: add the new form, migrate callers in batches, remove the old.
     Put them in one linear order: prefactor slices first, dependents after
     what they need, riskier independent slices lower so they're reviewed
     early. One slice is fine for a small change.

   Call the Skill tool for `show-me` and add a visual wherever it reads
   faster than prose, in its smallest fitting shape: module shape before
   and after, a `diff` on the call/file tree for where it lands, flow or
   sequence for data flow, the slice stack in order, a table for compared
   options. Put the whole draft spec in the `show-me` Markdown preview,
   the same Markdown and Mermaid the issue bodies will use (GitHub
   renders it); in chat give only the slice stack, rendered per
   `show-me`. Ask for an explicit yes, and on feedback edit the draft,
   re-run the preview and ask again.

4. **File** - one sub-issue per slice, in stack order:
   `gh issue create --parent N`, writing per the `issue` skill, title
   the slice with no prefix, label `spec`, body:

   ```md
   Intent: #N
   Stack: 2/4, after #a     <!-- first slice: "Stack: 1/4, base docs/intent-N-decisions" (or main) -->

   ## Requirements     <!-- the R-IDs this slice delivers, verbatim -->
   ## Design
   ## Interface        <!-- the pinned interface, per software-design's Planning step 4 -->
   ## Acceptance criteria   <!-- each cites its R-ID -->
   ## Open questions   <!-- carried forward; drop if empty -->
   ## Decisions        <!-- ADR links, resolved concerns -->
   ## Out of scope     <!-- drop if empty -->
   ```

   In the decisions worktree, commit the ADR / `CONTEXT.md` changes (per
   `commit`), push the branch, then `git worktree remove <dir>` so `build`
   can check it out. That branch is the bottom layer of the stack: add
   `Decisions: docs/intent-N-decisions` and a `## Requirements` list
   (each R-ID with the sub-issue that delivers it) to the intent body (per
   `issue`),
   and link the ADRs by path in the relevant sub-issues. Add the repo's
   **ready** label (per the `issue` skill's label discovery, e.g.
   `agent:ready`) to the intent, not the sub-issues, so `build` picks up
   the whole stack.

5. **Hand off** - list the sub-issue links in stack order; the next step is
   `/build #N` (the intent).

## Re-spec a blocked intent

When the intent already has sub-issues (`build` blocked it), amend rather
than refile. Read the blocked comments first; they say what broke. Grill
only the decisions they reopen. Check out the existing decisions branch
(`git fetch origin docs/intent-N-decisions`, then `git worktree add <dir>
docs/intent-N-decisions`, no `-b`) and record changes there. Edit
unshipped sub-issues in place per the `issue` skill's scope changes, file
new slices with `--parent N`, and leave sub-issues in **review** alone.
New slices go above the shipped ones; renumber every unshipped `Stack:`
line so the order stays linear.
Push, remove the worktree, then swap the intent **blocked -> ready**.
