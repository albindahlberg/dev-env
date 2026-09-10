#!/usr/bin/env bash
# PostToolUse hook: show the agent's current git worktree in the herdr sidebar.
# When cwd is a linked worktree, sets the pane's display-agent to "claude ⑂ <branch>";
# clears it back to the real agent name on the primary checkout or outside a repo.
set -euo pipefail

[[ "${HERDR_ENV:-}" == "1" && -n "${HERDR_PANE_ID:-}" ]] || exit 0
command -v herdr >/dev/null || exit 0

cwd=$(jq -r '.cwd // empty' 2>/dev/null) || exit 0
[[ -n "$cwd" ]] || exit 0

want=""   # empty => clear
br=""
if gd=$(git -C "$cwd" rev-parse --absolute-git-dir 2>/dev/null); then
  top=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || echo)
  # linked worktree git dir lives under <primary>/.git/worktrees/<name>
  if [[ "$gd" != "$top/.git" ]]; then
    br=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')
    br=${br#worktree-}; br=${br//+//}   # Claude Code names branches worktree-<name>, '+' for '/'
    want="claude ⑂ $br"
  fi
fi

# ponytail: PostToolUse fires per tool call; skip the socket RPC when unchanged
state="${TMPDIR:-/tmp}/cc-wt-label.${HERDR_PANE_ID//[^A-Za-z0-9]/_}"
[[ -f "$state" && "$(cat "$state" 2>/dev/null)" == "$want" ]] && exit 0
printf '%s' "$want" >"$state"

seq=$(date +%s%N)
if [[ -n "$want" ]]; then
  herdr pane report-metadata "$HERDR_PANE_ID" --source cc-worktree \
    --display-agent "$want" --seq "$seq" >/dev/null 2>&1 || true
  # a solo worktree workspace still labelled by repo name -> relabel to the branch
  if [[ -n "${HERDR_WORKSPACE_ID:-}" ]] \
     && [[ "$(herdr workspace get "$HERDR_WORKSPACE_ID" 2>/dev/null \
              | jq -r '.result.workspace.pane_count // 9')" == "1" ]]; then
    herdr workspace rename "$HERDR_WORKSPACE_ID" "⑂ $br" >/dev/null 2>&1 || true
  fi
else
  herdr pane report-metadata "$HERDR_PANE_ID" --source cc-worktree \
    --clear-display-agent --seq "$seq" >/dev/null 2>&1 || true
fi
exit 0
