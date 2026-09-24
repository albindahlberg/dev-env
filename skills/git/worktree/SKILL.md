---
name: worktree
description: Name git worktrees and their branches per Conventional Commits. Use whenever creating a worktree or branch (EnterWorktree, git worktree add, git switch -c).
---

# Worktree

Branch: `type/short-kebab-description`, with `type` from Conventional Commits
(`feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert`).
Optional scope: `type/scope-short-description`.

Worktree directory/name: same string with `/` -> `-`
(branch `feat/add-login` -> worktree `feat-add-login`).

Rules:
- lowercase, kebab-case, a-z 0-9 `-` only
- imperative, <= 40 chars after the type, no trailing dash
- type = dominant change of the work (same one the PR title/commits will use)
- ticket id allowed after type: `fix/ABC-123-null-session`
- never `wip`, `test`, `tmp`, `new-branch`, or random names

Examples:
- `feat/herdr-target-picker` -> `feat-herdr-target-picker`
- `fix/expired-token` -> `fix-expired-token`
- `chore/bump-deps` -> `chore-bump-deps`

If type unclear, ask once, don't guess `chore`.

## Creating it

Main session (not in a subagent): use `EnterWorktree` with the name above.

Inside a subagent: `EnterWorktree` refuses — it won't mutate a cwd-pinned
subagent's working directory. Use `git worktree add <dir> -b <branch>`
directly, same naming as above.
