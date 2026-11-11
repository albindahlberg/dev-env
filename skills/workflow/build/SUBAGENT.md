# Build one issue

You build one GitHub issue and hand back a committed, unpushed branch. The
coordinator that spawned you gave you the issue number, the repo and, in a
stack, the stack's worktree and current top branch. You have none of its
conversation.

Load each skill named below with the Skill tool before the step that uses
it. Build and commit locally only: the coordinator pushes, opens the PR
and runs the reviews.

1. **Claim** - `gh issue view N` to read title/body/comments. Follow the
   `issue` skill's "Working an issue" section: discover the repo's status
   labels, swap **ready -> working** (or just add working if the issue
   lacks ready but was explicitly named).
2. **Worktree** - create branch + worktree per the `worktree` skill, naming
   it from the issue's dominant change type and title, e.g.
   `fix/N-short-desc` -> worktree `fix-N-short-desc`.
   In a stack, see below.
3. **Build**, inside that worktree:
   - When the issue touches Python or TypeScript, follow `data-models` for
     every data shape it adds or changes.
   - Follow `software-design`'s Steps for each module the issue touches:
     the interface first, then the implementation behind it. With an
     `## Interface`, write that interface exactly as pinned, its one-line
     description as the interface comment. With none, pin the interface
     yourself per its Planning step 4 and list it in the hand back. A
     pinned interface that turns out wrong takes the blocked path (step 5)
     with what broke, so the fix lands in the spec.
   - Use `mattpocock-skills:tdd` where it fits. Tests go through the
     interfaces `## Interface` lists for them; with no `## Interface`,
     pick them yourself and list them in the hand back. Cover every
     scenario in `## Tests`, with as many tests as it takes, and add
     whatever else the implementation needs. A scenario that turns out
     wrong takes the blocked path when fixing it changes a requirement;
     otherwise refine or drop it and return it for the PR's Notes, with
     why. Each test pins
     one behaviour a caller relies on, using the real implementation
     behind the interface; a fake stands in only for a dependency the
     module doesn't own (network, vendor, clock). Domain terms live in
     the repo's glossary (`GLOSSARY.md` unless the repo uses another
     file).
   - Typecheck and run single test files regularly; full suite once at the end.
   - Done when lint, typecheck and the full suite are green and each
     requirement ID in the issue has a behaviour test through the
     interface that fails without the change.
   - Leave reviews to the coordinator.
   - Commit to the branch (per `commit`).
4. **Hand back** - return the branch name and worktree path with the branch
   committed and unpushed, plus any refined or dropped scenarios.
5. **Blocked/failure** - follow the `issue` skill's blocked path: post the
   blocked comment, swap **working -> blocked**, stop this subagent without
   touching the others.

## In a stack

When the coordinator gave you a stack worktree and top branch, the issue is
one layer of a PR stack:

- **Claim** - the sub-issue counts as explicitly named: add **working**.
- **Worktree** - work in the stack's worktree and add your branch on top
  with `gh stack add <branch>` (per `gh-stack`), named per `worktree`.
  With no stack worktree yet, create it per `worktree` and run
  `gh stack init <branch>` instead.
- **Scope** - build this sub-issue only, and leave the layers below as
  they are.
- **Blocked** - "the stack order is wrong" (the issue needs something from
  a later slice) is also blocked: take the blocked path with the order as
  filed.
