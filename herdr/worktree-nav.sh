#!/usr/bin/env bash
# herdr worktree navigator: fzf list of git worktrees for the focused repo,
# Enter opens (or focuses, if already open) that worktree's workspace.
# Bound via [[keys.command]] popup in config.toml.
set -euo pipefail

esc=$(printf '\033')

sel=$(
  herdr worktree list \
    | jq -r --arg e "$esc" '
        def pad($n): . + ([limit(([$n - length, 0] | max); repeat(" "))] | join(""));
        [ .result.worktrees[]
          | { path, branch: (.branch // "(detached)"),
              open: (.open_workspace_id != null),
              linked: .is_linked_worktree } ] as $rows
        | ($rows | map(.branch | length) | max) as $bw
        | $rows[]
        | (if .open then "\($e)[36m▸\($e)[0m " else "  " end) as $f
        | (if .linked then "\($e)[90m⌐\($e)[0m" else " " end) as $g
        | "\(.path)\t\($f)\($g) \($e)[32m\(.branch | pad($bw))\($e)[0m  \($e)[90m\(.path)\($e)[0m"
      ' \
    | fzf --ansi -1 --with-nth=2.. --delimiter='\t' \
          --bind=j:down,k:up,q:abort,one:accept \
          --prompt='worktree> ' --height=100% --reverse
) || exit 0

herdr worktree open --path "${sel%%$'\t'*}" --focus
