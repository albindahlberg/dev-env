#!/usr/bin/env bash
# herdr worktree navigator: fzf list of git worktrees for the focused repo.
#   Enter  open (or focus, if already open) the worktree(s) and close
#   tab    mark rows for a multi-select
#   d      remove marked (or current) worktrees; confirms, stays open
#   n      create a new worktree (branch = name); stays open
# Bound via [[keys.command]] popup in config.toml.
set -euo pipefail

esc=$(printf '\033')

# Resolve the repo from the triggering pane's cwd, not the focused-UI pane.
# herdr worktree list keys off --cwd; bare it uses whatever pane the UI focuses.
while true; do
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
      | fzf --ansi --multi --with-nth=5.. --delimiter='\t' --expect=d,n \
            --bind=j:down,k:up,q:abort \
            --header='enter: open   tab: mark   d: remove   n: new   q: quit' \
            --prompt='worktree> ' --height=100% --reverse
  ) || exit 0

  key=$(head -1 <<<"$out")
  mapfile -t rows < <(tail -n +2 <<<"$out")

  case "$key" in
    n)
      repo=$(jq -r '.result.source.repo_root' <<<"$wt")
      read -rp 'new worktree name (empty to cancel): ' name
      [[ -n "$name" ]] || continue
      herdr worktree create --cwd "$repo" --branch "${name// /-}" --no-focus >/dev/null \
        || read -rp 'create failed — enter to continue' _
      ;;
    d)
      targets=()
      for row in "${rows[@]}"; do
        IFS=$'\t' read -r path _ _ linked _ <<<"$row"
        if [[ "$linked" == "1" ]]; then targets+=("$row"); else echo "skipping primary worktree $path"; fi
      done
      (( ${#targets[@]} )) || { read -rp 'nothing to remove — enter to continue' _; continue; }
      printf '  %s\n' "${targets[@]%%$'\t'*}"
      read -rp "remove ${#targets[@]} worktree(s)? [y/N] " ans
      [[ "$ans" == [yY] ]] || continue
      failed=0
      for row in "${targets[@]}"; do
        IFS=$'\t' read -r path wsid repo _ _ <<<"$row"
        if [[ "$wsid" != "-" ]]; then
          herdr worktree remove --workspace "$wsid" --force >/dev/null
        else
          git -C "$repo" worktree remove --force "$path"
        fi || { echo "failed: $path"; failed=1; }
      done
      (( failed == 0 )) || read -rp 'enter to continue' _
      ;;
    *)
      for row in "${rows[@]}"; do
        IFS=$'\t' read -r path _ <<<"$row"
        herdr worktree open --path "$path" --focus >/dev/null
      done
      exit 0
      ;;
  esac
done
