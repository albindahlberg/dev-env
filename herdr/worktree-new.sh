#!/usr/bin/env bash
# herdr: prompt for a name, create a git worktree for the current repo, and open
# it in a new tab (shell cd'd into it). Bound via [[keys.command]] popup (prefix+t).
set -euo pipefail

repo=$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null) || {
  echo "not in a git repo: $PWD"; read -rp 'press enter to close' _; exit 0
}
# primary checkout = first entry in `git worktree list`; worktrees live under it
primary=$(git -C "$repo" worktree list --porcelain | awk '/^worktree /{print $2; exit}')

read -rp 'new worktree name: ' name
[[ -n "$name" ]] || exit 0
slug=${name// /-}

dir="$primary/.claude/worktrees/$slug"
[[ -e "$dir" ]] && { echo "already exists: $dir"; read -rp 'press enter to close' _; exit 0; }

# ponytail: branches from current HEAD; pass a ref to worktree add if you want origin/main
git -C "$primary" worktree add -b "$slug" "$dir" \
  || { read -rp 'worktree add failed — press enter to close' _; exit 1; }

herdr tab create --cwd "$dir" --label "⑂ $slug" --focus
