# claude

Portable `~/.claude` config. `../install.sh` links the tracked parts into `~/.claude/`.

Excluded (machine-local / secret): `.credentials.json`, `history.jsonl`,
`sessions/`, `projects/`, `tasks/`, `teams/`, `file-history/`, caches.

`skills/` here holds only symlinks into `../skills/<category>/<name>` (shared
with `codex/`, see `../AGENTS.md`) — `git/` (commit, worktree),
`github/` (pr, issue, gh-stack), `workflow/` (skewer, skewer-w-docs, work, show-me), `writing/` (unslop),
`dotfiles/` (config-sync). The category is a repo-side grouping only; the
symlinks here stay flat.

`hooks/secret-guard.sh` symlinks into `../hooks/` (also shared with `codex/`).

`settings.json` registers plugin marketplaces but leaves every plugin off by
default (`enabledPlugins` values are `false`). Enable what you want per machine —
those toggles stay local.

`hooks/herdr-agent-state.sh` is herdr-managed and untracked; `install.sh` runs
`herdr integration install claude` to create it.
