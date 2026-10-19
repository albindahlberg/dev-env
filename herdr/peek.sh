#!/usr/bin/env bash
set -euo pipefail

if [ $# -gt 0 ]; then
  cmd="nvim -R -c 'set nolist' -c 'silent! IBLDisable' $(printf %q "$(realpath "$1")")"
else
  cmd="nvim -c DiffviewOpen -c 'tabclose 1'"
fi
cur=$(herdr pane current)
[ $# -gt 0 ] || cd "$(jq -r .result.pane.foreground_cwd <<<"$cur")"

pane=$(herdr pane split "$(jq -r .result.pane.pane_id <<<"$cur")" --direction right --cwd "$PWD" --no-focus | jq -r .result.pane.pane_id)
herdr pane run "$pane" "$cmd; exit"
