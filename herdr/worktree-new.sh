#!/usr/bin/env bash
# herdr: prompt for a name, then create a Git worktree for the current repo as a
# new herdr workspace (space), focused. Bound via [[keys.command]] popup (prefix+t).
set -euo pipefail

repo=$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null) || {
  echo "not in a git repo: $PWD"; read -rp 'press enter to close' _; exit 0
}

read -rp 'new worktree name: ' name
[[ -n "$name" ]] || exit 0
slug=${name// /-}

herdr worktree create --cwd "$repo" --branch "$slug" --label "⑂ $slug" --focus \
  || { read -rp 'worktree create failed — press enter to close' _; exit 1; }
