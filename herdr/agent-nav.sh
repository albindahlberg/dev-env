#!/usr/bin/env bash
# herdr agent navigator: fzf list of live agents, Enter focuses that agent's pane.
# Shows each agent's actual worktree (repo/branch, from its foreground cwd) so you
# can see where work is happening even when the agent never changed herdr workspace.
# Bound via [[keys.command]] popup in config.toml.
set -euo pipefail

esc=$(printf '\033')
ws=$(herdr workspace list)
agents=$(herdr agent list)

# pane_id -> "repo/branch" for each agent's foreground cwd (blank if not a repo)
brmap=$(
  jq -r '.result.agents[] | "\(.pane_id)\t\(.foreground_cwd)"' <<<"$agents" \
    | while IFS=$'\t' read -r pane fg; do
        top=$(git -C "$fg" rev-parse --show-toplevel 2>/dev/null) \
          && br=$(git -C "$fg" rev-parse --abbrev-ref HEAD 2>/dev/null) \
          && printf '%s\t%s/%s\n' "$pane" "${top##*/}" "$br" \
          || printf '%s\t\n' "$pane"
      done \
    | jq -R -s 'split("\n") | map(select(length>0) | split("\t"))
               | map({(.[0]): (.[1] // "")}) | add // {}'
)

# Row: <pane_id>\t<focus>< glyph status>  <dim workspace · kind · worktree>  <title>
# Columns are padded on the PLAIN text, then wrapped in SGR, so widths line up.
# pane_id is hidden (--with-nth=2..); fzf --ansi renders the colors.
sel=$(
  jq -r --arg e "$esc" --argjson ws "$ws" --argjson br "$brmap" '
      def pad($n): . + ([limit(([$n - length, 0] | max); repeat(" "))] | join(""));
      ($ws.result.workspaces | map({(.workspace_id): (.label // .name // .workspace_id)}) | add) as $wsmap
      | [ .result.agents[]
          | { pane: .pane_id, foc: .focused, s: .agent_status,
              wsl: ($wsmap[.workspace_id] // .workspace_id), kind: .agent,
              wt: ($br[.pane_id] // ""),
              title: .terminal_title_stripped } ] as $rows
      | ($rows | map(.s   | length) | max) as $sw
      | ($rows | map(.wsl | length) | max) as $ww
      | ($rows | map(.kind| length) | max) as $kw
      | ($rows | map(.wt  | length) | max) as $tw
      | $rows[]
      | (if .foc then "\($e)[36m▸\($e)[0m " else "  " end) as $f
      | ({working:"33",idle:"32",blocked:"31;1",done:"36",unknown:"90"}[.s] // "37") as $c
      | ({working:"◑",idle:"○",blocked:"▲",done:"✔",unknown:"?"}[.s] // "•") as $g
      | "\(.pane)\t\($f)\($e)[\($c)m\($g) \(.s | pad($sw))\($e)[0m  \($e)[90m\(.wsl | pad($ww))  \(.kind | pad($kw))\($e)[0m  \($e)[35m\(.wt | pad($tw))\($e)[0m  \(.title)"
    ' <<<"$agents" \
    | fzf --ansi -1 --with-nth=2.. --delimiter='\t' \
          --bind=j:down,k:up,q:abort,one:accept \
          --prompt='agent> ' --height=100% --reverse
) || exit 0

# ponytail: rows have exactly one tab; strip from it to recover the pane_id
herdr agent focus "${sel%%$'\t'*}"
