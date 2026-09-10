#!/usr/bin/env bash
# herdr worktree navigator: fzf list of git worktrees for the focused repo.
#   Enter  open (or focus, if already open) that worktree's workspace
#   d      remove that worktree (herdr if open, git otherwise); confirms first
# Bound via [[keys.command]] popup in config.toml.
set -euo pipefail

esc=$(printf '\033')

# Resolve the repo from the triggering pane's cwd, not the focused-UI pane.
# herdr worktree list keys off --cwd; bare it uses whatever pane the UI focuses.
wt=$(herdr worktree list --cwd "$PWD" 2>/dev/null) || wt=""
if [[ -z "$wt" ]] || [[ "$(jq -r '.result.worktrees | length' <<<"$wt" 2>/dev/null)" == "0" ]]; then
  echo "no git worktrees for $PWD"
  read -rp 'press enter to close' _
  exit 0
fi

# Hidden cols: path \t workspace_id \t repo_root \t linked(0|1) \t <display>
out=$(
  jq -r --arg e "$esc" '
        def pad($n): . + ([limit(([$n - length, 0] | max); repeat(" "))] | join(""));
        .result.source.repo_root as $repo
        | [ .result.worktrees[]
            | { path, repo: $repo,
                branch: (.branch // "(detached)"),
                wsid: (.open_workspace_id // "-"),
                linked: (if .is_linked_worktree then "1" else "0" end) } ] as $rows
        | ($rows | map(.branch | length) | max) as $bw
        | $rows[]
        | (if .wsid != "-" then "\($e)[36m▸\($e)[0m " else "  " end) as $f
        | (if .linked == "1" then "\($e)[90m⌐\($e)[0m" else " " end) as $g
        | "\(.path)\t\(.wsid)\t\(.repo)\t\(.linked)\t\($f)\($g) \($e)[32m\(.branch | pad($bw))\($e)[0m  \($e)[90m\(.path)\($e)[0m"
      ' <<<"$wt" \
    | fzf --ansi -1 --with-nth=5.. --delimiter='\t' --expect=d \
          --bind=j:down,k:up,q:abort,one:accept \
          --header='enter: open   d: remove' \
          --prompt='worktree> ' --height=100% --reverse
) || exit 0

key=$(head -1 <<<"$out")
row=$(tail -1 <<<"$out")
IFS=$'\t' read -r path wsid repo linked _ <<<"$row"

if [[ "$key" != "d" ]]; then
  herdr worktree open --path "$path" --focus
  exit 0
fi

if [[ "$linked" != "1" ]]; then
  echo "refusing to remove the primary worktree ($path)"
  read -rp 'press enter to close' _
  exit 0
fi

read -rp "remove worktree $path ? [y/N] " ans
[[ "$ans" == [yY] ]] || exit 0

if [[ "$wsid" != "-" ]]; then
  herdr worktree remove --workspace "$wsid" --force
else
  git -C "$repo" worktree remove --force "$path"
fi || { read -rp 'remove failed — enter to close' _; exit 1; }
