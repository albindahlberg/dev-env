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
- lowercase, kebab-case, a-z 0-9 `-` only (a JIRA key keeps its case)
- imperative, <= 40 chars after the type, no trailing dash
- type = dominant change of the work (same one the PR title/commits will use)
- never `wip`, `test`, `tmp`, `new-branch`, or random names

Ticket prefix after the type, first match wins:
1. JIRA ticket: its key, `chore/K-213-kebab-desc`
2. GitHub issue: its number, `chore/231-kebab-desc`
3. Neither: no prefix, `chore/kebab-desc`

Examples:
- `feat/herdr-target-picker` -> `feat-herdr-target-picker`
- `fix/expired-token` -> `fix-expired-token`
- `chore/bump-deps` -> `chore-bump-deps`

If type unclear, ask once, don't guess `chore`.

## Creating it

Every worktree lives in `~/.herdr/worktrees/<repo>/<name>`, `<repo>` the
repository's directory name and `<name>` the worktree name above. herdr
lists and opens them from there, and nothing lands inside the repo, where
a worktree under `.claude/` shows every project skill twice.

New branch: `git worktree add ~/.herdr/worktrees/<repo>/<name> -b <branch>`.

Existing branch (work that's already there, e.g. a pushed branch):
`git fetch origin <branch>`, then the same `git worktree add` with
`<branch>` in place of `-b <branch>`. It fails if another worktree holds
the branch; remove that one first.

Main session that will do the work itself: after creating it, call
`EnterWorktree` with `path` set to the new directory. A coordinator that
hands the worktree to subagents stays where it is. Calling it with `name` creates the worktree under
`.claude/worktrees/` instead.

Subagent: work in the directory by path (`git -C <dir>`, absolute file
paths). `EnterWorktree` only enters worktrees under `.claude/worktrees/`
from a subagent.
