---
name: commit
description: Enforce Conventional Commits for every git commit message. Use whenever creating, amending, or suggesting a commit.
---

# Commit

Format: `type(scope)?: description`

- type: `feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert`
- subject <= 50 chars, imperative mood, lowercase, no trailing period
- scope optional; short noun for the area touched (`nvim`, `auth`)
- one line only: no body, no footers. Use `git commit -m "<subject>"`
- exception: a required attribution trailer (e.g. `Co-Authored-By:`) is
  allowed; add it with `--trailer "Co-Authored-By: ..."`, nothing else
- *why* that doesn't fit the subject goes in the PR, not the commit
- breaking change: `type!:` (no `BREAKING CHANGE:` footer)
- one logical change per commit; pick the type of the dominant change

Examples:
- `feat(herdr): add just target picker`
- `fix(auth): handle expired token`
- `refactor: drop unused helper`
