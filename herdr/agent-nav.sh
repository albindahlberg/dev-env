#!/usr/bin/env bash
# herdr agent navigator: fzf list of live agents, Enter focuses that agent's pane.
# Bound via [[keys.command]] popup in config.toml.
set -euo pipefail

esc=$(printf '\033')
ws=$(herdr workspace list)

# Row: <pane_id>\t<focus>< glyph status>  <dim workspace> · <dim kind>  <title>
# Columns are padded on the PLAIN text, then wrapped in SGR, so widths line up.
# pane_id is hidden (--with-nth=2..); fzf --ansi renders the colors.
sel=$(
  herdr agent list \
    | jq -r --arg e "$esc" --argjson ws "$ws" '
        def pad($n): . + ([limit(([$n - length, 0] | max); repeat(" "))] | join(""));
        ($ws.result.workspaces | map({(.workspace_id): (.label // .name // .workspace_id)}) | add) as $wsmap
        | [ .result.agents[]
            | { pane: .pane_id, foc: .focused, s: .agent_status,
                wsl: ($wsmap[.workspace_id] // .workspace_id), kind: .agent,
                title: .terminal_title_stripped } ] as $rows
        | ($rows | map(.s   | length) | max) as $sw
        | ($rows | map(.wsl | length) | max) as $ww
        | ($rows | map(.kind| length) | max) as $kw
        | $rows[]
        | (if .foc then "\($e)[36m▸\($e)[0m " else "  " end) as $f
        | ({working:"33",idle:"32",blocked:"31;1",done:"36",unknown:"90"}[.s] // "37") as $c
        | ({working:"◑",idle:"○",blocked:"▲",done:"✔",unknown:"?"}[.s] // "•") as $g
        | "\(.pane)\t\($f)\($e)[\($c)m\($g) \(.s | pad($sw))\($e)[0m  \($e)[90m\(.wsl | pad($ww))  \(.kind | pad($kw))\($e)[0m  \(.title)"
      ' \
    | fzf --ansi -1 --with-nth=2.. --delimiter='\t' \
          --bind=j:down,k:up,q:abort,one:accept \
          --prompt='agent> ' --height=100% --reverse
) || exit 0

# ponytail: rows have exactly one tab; strip from it to recover the pane_id
herdr agent focus "${sel%%$'\t'*}"
