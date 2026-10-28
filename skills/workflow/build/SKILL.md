---
name: build
description: 'Implement one or more GitHub issues in parallel, each in its own worktree, with lifecycle labels and a draft PR at the end. An intent issue with spec sub-issues is built as one PR stack. Use when asked to implement, build, fix, or pick up one or more issue numbers (e.g. "build #12", "build #45 and #46").'
---

# Build

Take one or more issue numbers. Spawn one subagent per issue (parallel Agent
calls in a single message). Each subagent runs the pipeline below for its
issue only, isolated in its own worktree.

Nothing reaches GitHub until it has passed the **Review gate**: subagents
build and commit locally, and the coordinator reviews, fixes and ships.

An **intent** (has sub-issues from `spec`, each body with a `Stack: n/m`
line) is built as one PR stack instead - see **Stack mode**. Stacks for
different intents run in parallel with each other and with plain issues.

## Coordinator

1. For each issue number, `gh issue view N` first: confirm it exists and
   isn't already `agent:working`/assigned to someone else. Skip + report any
   that fail this check; only the rest get a subagent.
2. Discover (and create missing) status labels per the `issue` skill here,
   once, so subagents don't race.
3. Launch remaining issues as parallel `general-purpose` subagents, one per
   issue, single message, multiple Agent tool calls. Give each subagent the
   issue number and this skill's steps — it has no memory of this
   conversation.
4. As each subagent hands back its branch, run the **Review gate** on it,
   then **Ship** it.
5. Report one final summary: per issue, PR link plus findings fixed and
   dismissed, or blocked/skip reason. Don't repeat subagent tool output.

## Per-issue pipeline (subagent)

1. **Claim** - `gh issue view N` to read title/body/comments. Follow the
   `issue` skill's "Working an issue" section: discover the repo's status
   labels, swap **ready -> working** (or just add working if the issue
   lacks ready but was explicitly named).
2. **Worktree** - create branch + worktree per the `worktree` skill, naming
   it from the issue's dominant change type and title, e.g.
   `fix/N-short-desc` -> worktree `fix-N-short-desc`.
3. **Build**, inside that worktree:
   - Follow `software-design`'s Steps for each module the issue touches:
     the interface first, then the implementation behind it. With an
     `## Interface`, write that interface exactly as pinned, its one-line
     description as the interface comment. With none, pin the interface
     yourself per its Planning step 4 and list it in the hand back. A
     pinned interface that turns out wrong takes the blocked path (step 5)
     with what broke, so the fix lands in the spec.
   - Use `mattpocock-skills:tdd` where it fits. Tests go through the
     interfaces `## Interface` lists for them; with no `## Interface`,
     pick them yourself and list them in the hand back. Each test pins
     one behaviour a caller relies on, using the real implementation
     behind the interface; a fake stands in only for a dependency the
     module doesn't own (network, vendor, clock). Domain terms live in
     `CONTEXT.md`.
   - Typecheck and run single test files regularly; full suite once at the end.
   - Done when lint, typecheck and the full suite are green and each acceptance criterion has
     a behaviour test through the interface that fails without the
     change.
   - Leave reviews to the coordinator.
   - Commit to the branch (per `commit`).
4. **Hand back** - return the branch name and worktree path with the branch
   committed and unpushed.
5. **Blocked/failure** - follow the `issue` skill's blocked path: post the
   blocked comment, swap **working -> blocked**, stop this subagent without
   touching the others.

## Review gate

Runs in the coordinator on the local branch, before anything is pushed.

1. Run `code-review <branch>` and `software-design`'s Review on the branch's
   diff against its base (in a stack, the layer below, so each review
   covers this layer only), giving the Review the issue number. When the
   diff touches auth, permissions, secrets, user data or external input,
   also run the built-in `security-review` from the branch's worktree.
   They spawn their own subagents, which a subagent can't, so they run
   here.
2. No findings and no flags: go to **Ship**. Otherwise spawn one fresh
   subagent in the branch's worktree, given every finding and flag
   verbatim (it has no memory of the review). It fixes each code-review
   and security finding, each unmet requirement ID, and each
   **mechanical** flag, or dismisses one only if it's wrong, inside the
   modules the branch already touches. It conforms the code to any
   `## Interface` mismatch; one it can't conform without changing the
   interface is returned as blocking. It leaves **judgement** flags as
   they are. A finding and a flag on the
   same problem are fixed once. When the two conflict, a correctness bug
   wins, and a cleanup that would break the `## Interface` or trip a red
   flag is dismissed with that conflict as its reason. A finding outside
   the touched modules is returned for the PR's Notes. It reruns the
   tests and commits per `commit`; tests it can't get green are returned
   as blocking.
3. The subagent returns the dismissed findings with reasons, the
   judgement flags, and anything blocking. Blocking takes the issue's
   blocked path (`issue` skill) instead of **Ship**. Dismissals go in the coordinator's final report only;
   one that reflects a real design decision also goes in the PR body's
   Notes, written as a statement about the design.

## Ship

Runs in the coordinator, in the branch's worktree, after the Review gate.

1. Push the branch and open the PR **as draft** (`gh pr create --draft`),
   title/body per the `pr` skill, body includes `Closes #N`. List each
   judgement flag in the body's Notes with its `file:line` and trade-off,
   written as an open design question. The PR describes the change, never
   the review.
2. Swap the issue label **working -> review** (`issue` skill), comment on
   the issue with the PR link.

## Stack mode (intent)

The coordinator runs the stack; order comes from the sub-issues' `Stack:`
lines, kept as `spec` set it.

1. `gh issue view N` the intent, list its sub-issues, sort by `Stack:`.
   Claim the intent (**ready -> working**). When the intent body has a
   `Decisions: <branch>` line, `git fetch origin <branch>` and create the
   stack's worktree on it per `worktree` (existing branch, no `-b`), then
   adopt it as the bottom layer with `gh stack init <branch>` (per
   `gh-stack`). It was settled in the `spec` grill, so it skips the Review
   gate; at the first submit, edit its PR's title/body per `pr` with
   `Part of #N`.
   **Resuming** a re-specced intent: sub-issues already in **review** are
   shipped; check out the stack's top shipped branch in a worktree and
   `gh stack checkout <branch>`, then continue from the first unshipped
   slice.
2. One fresh subagent per sub-issue, **sequentially** - wait for each
   before spawning the next, so every agent starts with a clean context
   and the previous layers already in its base branch. Each runs the
   per-issue pipeline with these changes:
   - **Prompt** - the coordinator gives it the stack's worktree path and
     the current top branch.
   - **Claim** - the sub-issue counts as explicitly named: add
     **working**.
   - **Worktree** - all reuse the stack's worktree and run
     `gh stack add <branch>` (per `gh-stack`). With no decisions branch,
     the first creates that worktree per `worktree` and runs
     `gh stack init <branch>` instead.
   - **Blocked** - including "the stack order is wrong" (needs something
     from a later slice): blocked path, order as filed. Stop the stack and
     take the intent **working -> blocked** with a blocked comment linking
     the sub-issue; the fix belongs in the spec (`spec`'s re-spec path).
3. **Per layer** - when a layer hands back, the coordinator runs the
   **Review gate** on it, then ships it in place of **Ship**'s step 1:
   1. `gh stack submit --auto`. If it fails because the repo has no
      stacked PRs, `git push` the branch and
      `gh pr create --draft --base <layer below>` instead.
   2. `gh pr edit` the layer's PR title/body per `pr`, with
      `Closes #<sub-issue>` and the judgement flags in Notes.
   3. **Ship**'s step 2 for the sub-issue.

   The next layer starts only after, so each layer builds on
   reviewed code.
4. **Outcome gate** - check every Proposed outcome box of the intent
   against the shipped stack and tick each one delivered, appending the
   PR that delivers it (`- [x] ... (#42)`). All ticked: put `Closes #N` in
   the top PR (GitHub doesn't close a parent when its sub-issues close).
   Any unticked: put `Part of #N` there instead and list the unticked
   boxes in the report.
5. Swap the intent **working -> review**; report the stack's PR links in
   order plus findings fixed and dismissed.

This skill only sequences `issue`, `worktree`, `pr`, `commit`, `gh-stack`,
`code-review`, `software-design` and `mattpocock-skills:tdd` - it doesn't
restate their rules, follow them directly.
