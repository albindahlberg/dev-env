---
name: conventional-commit
description: Enforce Conventional Commits for every git commit message. Use whenever creating, amending, or suggesting a commit.
---

# Conventional Commit

Format: `type(scope)?: description`

- type: `feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert`
- subject <= 50 chars, imperative mood, lowercase, no trailing period
- scope optional; short noun for the area touched (`nvim`, `auth`)
- body only when *why* isn't obvious; wrap at 72, blank line after subject
- breaking change: `type!:` and/or `BREAKING CHANGE:` footer
- one logical change per commit; pick the type of the dominant change

Examples:
- `feat(herdr): add just target picker`
- `fix(auth): handle expired token`
- `refactor: drop unused helper`

Same types are reused for branch/worktree names (see `worktree-naming`) and PR titles (see `pr`).
