# claude

Portable `~/.claude` config. Copy contents into `~/.claude/`.

Excluded (machine-local / secret): `.credentials.json`, `history.jsonl`,
`sessions/`, `projects/`, `tasks/`, `teams/`, `file-history/`, caches.

`settings.json` registers plugin marketplaces but leaves every plugin off by
default (`enabledPlugins` values are `false`). Enable what you want per machine —
those toggles stay local.

`hooks/herdr-agent-state.sh` is herdr-managed and overwritten on herdr reinstall.
