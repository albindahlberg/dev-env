---
name: build
description: 'Implement one or more GitHub issues in parallel, each in its own worktree, with lifecycle labels and a draft PR at the end. An intent issue with spec sub-issues is built as one PR stack. Use when asked to implement, build, fix, or pick up one or more issue numbers (e.g. "build #12", "build #45 and #46").'
---

# Build

Take one or more issue numbers. Spawn one subagent per issue (parallel Agent
calls in a single message). Each subagent runs the pipeline below for its
issue only, isolated in its own worktree.

An **intent** (has sub-issues from `spec`, each body with a `Stack: n/m`
line) is built as one PR stack instead - see **Stack mode**. Stacks for
different intents run in parallel with each other and with plain issues.

## Coordinator

1. For each issue number, `gh issue view N` first: confirm it exists and
   isn't already `agent:working`/assigned to someone else. Skip + report any
   that fail this check, don't spawn a subagent for them.
2. Discover the repo's status labels (`issue` skill). For each of
   **working**, **review** and **blocked** with no match, create it as
   `agent:<state>` (`gh label create`), overriding the `issue` skill's
   don't-create rule. Do it here, once, so subagents don't race.
3. Launch remaining issues as parallel `general-purpose` subagents, one per
   issue, single message, multiple Agent tool calls. Give each subagent the
   issue number and this skill's steps — it has no memory of this
   conversation.
4. Wait for all subagents. For each draft PR, run
   `mattpocock-skills:code-review` on its branch here in the coordinator
   (it spawns its own sub-agents, which a subagent can't), then post the
   findings as a PR comment.
5. Report one final summary: per issue, PR link plus review verdict, or
   blocked/skip reason. Don't repeat subagent tool output.

## Per-issue pipeline (subagent)

1. **Claim** - `gh issue view N` to read title/body/comments. Follow the
   `issue` skill's "Working an issue" section: discover the repo's status
   labels, swap **ready -> working** (or just add working if the issue
   lacks ready but was explicitly named).
2. **Worktree** - create branch + worktree per the `worktree` skill, naming
   it from the issue's dominant change type and title, e.g.
   `fix/N-short-desc` -> worktree `fix-N-short-desc`.
3. **Implement**, inside that worktree:
   - Use `mattpocock-skills:tdd` where it fits, at pre-agreed seams.
   - Typecheck and run single test files regularly; full suite once at the end.
   - Don't run `mattpocock-skills:code-review` here; the coordinator does.
   - Commit to the branch (per `commit`).
4. **Ship** - push the branch, open the PR **as draft**
   (`gh pr create --draft`), title/body per the `pr` skill, body includes
   `Closes #N`. Swap the issue label **working -> review** (`issue` skill),
   comment on the issue with the PR link.
5. **Blocked/failure** - follow the `issue` skill's blocked path: post the
   blocked comment, swap **working -> blocked**, stop this subagent without
   touching the others.

## Stack mode (intent)

The coordinator runs the stack; order comes from the sub-issues' `Stack:`
lines, never re-decided here.

1. `gh issue view N` the intent, list its sub-issues, sort by `Stack:`.
   Claim the intent (**ready -> working**).
2. One fresh subagent per sub-issue, **sequentially** - wait for each
   before spawning the next, so every agent starts with a clean context
   and the previous layers already in its base branch. Each runs the
   per-issue pipeline with these changes:
   - **Worktree** - the first creates the stack's worktree per `worktree`
     and runs `gh stack init <branch>`; later ones reuse that worktree and
     run `gh stack add <branch>` (per `gh-stack`).
   - **Ship** - `gh stack submit --auto`, then `gh pr edit` its own PR's
     title/body per `pr`, `Closes #<sub-issue>`. The top PR also gets
     `Closes #N` (GitHub doesn't close a parent when its sub-issues close).
   - **Blocked** - including "the stack order is wrong" (needs something
     from a later slice): blocked path, don't reorder. Stop the stack; the
     fix belongs in the spec.
   - **Review gate** - after each layer ships, the coordinator runs
     `code-review` on it and posts the findings on its PR. Correctness or
     design findings get fixed on that branch (a fresh subagent given the
     findings) before the next layer starts; nits stay as PR comments.
     Layers above are never built on known-broken code.
3. Swap the intent **working -> review**; report the stack's PR links in
   order plus verdicts.

This skill only sequences `issue`, `worktree`, `pr`, `commit`,
`gh-stack` and the mattpocock `tdd`/`code-review` skills - it doesn't restate their
rules, follow them directly.
