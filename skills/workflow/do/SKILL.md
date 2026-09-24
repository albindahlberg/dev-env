---
name: do
description: 'Implement one or more GitHub issues in parallel, each in its own worktree, with lifecycle labels and a draft PR at the end. Use when asked to implement, build, fix, or pick up one or more issue numbers (e.g. "do #12", "do #45 and #46").'
---

# Do

Take one or more issue numbers. Spawn one subagent per issue (parallel Agent
calls in a single message). Each subagent runs the pipeline below for its
issue only, isolated in its own worktree.

## Coordinator

1. For each issue number, `gh issue view N` first: confirm it exists and
   isn't already `agent:working`/assigned to someone else. Skip + report any
   that fail this check, don't spawn a subagent for them.
2. Launch remaining issues as parallel `general-purpose` subagents, one per
   issue, single message, multiple Agent tool calls. Give each subagent the
   issue number and this skill's steps — it has no memory of this
   conversation.
3. Wait for all subagents. Report one final summary: per issue, PR link or
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
   - Run `mattpocock-skills:code-review` on the result.
   - Commit to the branch (per `commit`).
4. **Ship** - push the branch, open the PR **as draft**
   (`gh pr create --draft`), title/body per the `pr` skill, body includes
   `Closes #N`. Swap the issue label **working -> review** (`issue` skill),
   comment on the issue with the PR link.
5. **Blocked/failure** - follow the `issue` skill's blocked path: post the
   blocked comment, swap **working -> blocked**, stop this subagent without
   touching the others.

This skill only sequences `issue`, `worktree`, `pr`, `commit`,
and the mattpocock `tdd`/`code-review` skills - it doesn't restate their
rules, follow them directly.
