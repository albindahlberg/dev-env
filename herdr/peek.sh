#!/usr/bin/env bash
set -euo pipefail

cur=$(herdr pane current)
if [ $# -gt 0 ]; then
  file=$(realpath "$1")
  sock="${XDG_RUNTIME_DIR:-/tmp}/peek-$(jq -r .result.pane.pane_id <<<"$cur" | tr : -).sock"
  if nvim --server "$sock" --remote-expr 1 >/dev/null 2>&1; then
    nvim --server "$sock" --remote-send "<C-\\><C-n>:view! $(printf %q "$file")<CR>"
    exit
  fi
  rm -f "$sock"
  cmd="nvim -R --listen $(printf %q "$sock") -c 'set nolist' -c 'silent! IBLDisable' $(printf %q "$file")"
else
  cmd="nvim -c DiffviewOpen -c 'tabclose 1'"
fi
[ $# -gt 0 ] || cd "$(jq -r .result.pane.foreground_cwd <<<"$cur")"

pane=$(herdr pane split "$(jq -r .result.pane.pane_id <<<"$cur")" --direction right --cwd "$PWD" --no-focus | jq -r .result.pane.pane_id)
herdr pane run "$pane" "$cmd; exit"
