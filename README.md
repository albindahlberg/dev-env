# dev-env

Portable dev config: nvim, tmux, herdr, k9s, pi, claude, codex. See `AGENTS.md`
for how the agent-tool configs (`claude/`, `codex/`) are put together.

```sh
git clone <repo> && cd dev-env
./install.sh --dry-run   # preview
./install.sh             # install missing tools, symlink configs
```

Flags: `--dry-run`, `--no-packages`, `--no-links`. Idempotent; anything already at
a link target is moved to `<target>.bak.<timestamp>`.

| Config | Linked to |
|---|---|
| `nvim/` | `~/.config/nvim` |
| `k9s/` | `~/.config/k9s` |
| `herdr/config.toml` | `~/.config/herdr/config.toml` |
| `tmux.conf` | `~/.tmux.conf` |
| `pi/` | `~/.pi` |
| `claude/scripts/`, `claude/hooks/*`, `claude/skills/*` | `~/.claude/...` (file by file) |
| `claude/settings.json` | copied once to `~/.claude/settings.json`, not linked |
| `codex/hooks/*`, `codex/skills/*` | `~/.codex/...` (file by file) |
| `codex/config.toml` | copied once to `~/.codex/config.toml`, not linked |

`skills/` and `hooks/` at the repo root are shared between `claude/` and
`codex/` — both tool dirs hold symlinks into them, not copies. `skills/` is
grouped by category (`github/`, `git/`, `workflow/`, `writing/`, ...); the live `~/.claude` and
`~/.codex` skill dirs stay flat regardless. See `AGENTS.md`.

Tools come from Homebrew (installed if missing) plus the official installers for
claude, herdr and pi. Public repo: never commit credentials, sessions or history.
See `AGENTS.md`, `claude/README.md`, `codex/README.md`.
