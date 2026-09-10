#!/usr/bin/env bash
# WorktreeCreate hook — CAPTURE MODE.
# Logs the stdin payload + relevant env, then exits 1 to abort creation cleanly
# (nothing half-made). Once we know the contract, this becomes the real hook that
# calls `herdr worktree create` so herdr owns Claude's worktrees natively.
set -euo pipefail

log=~/.claude/worktree-hook.log
{
  echo "=== $(date -Is) WorktreeCreate ==="
  echo "-- stdin --"
  cat
  echo
  echo "-- env --"
  env | grep -E '^(CLAUDE|HERDR|ANTHROPIC)_' | sort
  echo
} >>"$log" 2>&1

exit 1
