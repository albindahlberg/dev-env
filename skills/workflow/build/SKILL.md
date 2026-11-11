---
name: build
description: 'Implement one or more GitHub issues in parallel, each in its own worktree, with lifecycle labels and a draft PR at the end. An intent issue with spec sub-issues is built as one PR stack. Use when asked to implement, build, fix, or pick up one or more issue numbers (e.g. "build #12", "build #45 and #46").'
---

# Build

Take one or more issue numbers. Spawn one subagent per issue (parallel Agent
calls in a single message). Each subagent runs [SUBAGENT.md](SUBAGENT.md)
for its issue only, isolated in its own worktree.

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
   issue, single message, multiple Agent tool calls. Each gets the
   **Brief** below and nothing else.
4. As each subagent hands back its branch, run the **Review gate** on it,
   then **Ship** it.
5. Report one final summary: per issue, PR link plus findings fixed and
   dismissed, or blocked/skip reason. Don't repeat subagent tool output.

## Brief

A subagent has no memory of this conversation, so its prompt is this,
filled in, with absolute paths:

```
Read <this skill's directory>/SUBAGENT.md and follow it.
Issue: #<N> in <owner/repo>
Repo: <path to the main checkout>
```

In a stack, add:

```
Intent: #<intent>, layer <n>/<m>
Stack worktree: <path>
Top branch: <branch>
```

Anything else the subagent needs that the issue doesn't say goes on a
final `Context:` line. The pipeline itself stays in the file.

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
   subagent with this prompt, filled in:

   ```
   Read <this skill's directory>/FIX.md and follow it.
   Issue: #<N> in <owner/repo>
   Worktree: <path>
   Branch: <branch>, base <base>
   Findings and flags, verbatim:
   <every finding and flag>
   ```
3. Blocking takes the issue's blocked path (`issue` skill) instead of
   **Ship**. Dismissals go in the coordinator's final report only; one
   that reflects a real design decision also goes in the PR body's Notes
   (per `pr`), written as a statement about the design.

## Ship

Runs in the coordinator, in the branch's worktree, after the Review gate.

1. Push the branch and open the PR **as draft** (`gh pr create --draft`),
   title/body per the `pr` skill, body includes `Closes #N`. List each
   judgement flag in the body's Notes with its `file:line` and trade-off,
   written as an open design question, and each refined or dropped
   scenario with why. The PR describes the change, never
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
   and the previous layers already in its base branch. Each gets the
   **Brief** with its stack lines. When one comes back blocked, stop the
   stack and take the intent **working -> blocked** with a blocked
   comment linking the sub-issue; the fix belongs in the spec (`spec`'s
   re-spec path).
3. **Per layer** - when a layer hands back, the coordinator runs the
   **Review gate** on it, then ships it in place of **Ship**'s step 1:
   1. `gh stack submit --auto`. If it fails because the repo has no
      stacked PRs, `git push` the branch and
      `gh pr create --draft --base <layer below>` instead.
   2. `gh pr edit` the layer's PR title/body per `pr`, with
      `Closes #<sub-issue>`, and the judgement flags and scenario
      changes in Notes.
   3. If this layer isn't the bottom, also add `Closes #<sub-issue>` to
      the bottom PR's body. The stack merges in one go and GitHub only
      reads closing keywords from the PR into the default branch, so the
      layer's own `Closes` never fires.
   4. **Ship**'s step 2 for the sub-issue.

   The next layer starts only after, so each layer builds on
   reviewed code.
4. **Outcome gate** - check every Proposed outcome box of the intent
   against the shipped stack and tick each one delivered, appending the
   PR that delivers it (`- [x] ... (#42)`). All ticked: put `Closes #N` in
   the bottom PR (GitHub doesn't close a parent when its sub-issues close).
   Any unticked: put `Part of #N` there instead and list the unticked
   boxes in the report.
5. Check that `gh pr view <bottom PR> --json closingIssuesReferences` lists
   every sub-issue, plus the intent when all boxes were ticked.
6. Swap the intent **working -> review**; report the stack's PR links in
   order plus findings fixed and dismissed.

This skill only sequences `issue`, `worktree`, `pr`, `commit`, `gh-stack`,
`code-review`, `security-review`, `software-design`, `data-models` and
`mattpocock-skills:tdd` - it doesn't restate their rules, follow them
directly.
