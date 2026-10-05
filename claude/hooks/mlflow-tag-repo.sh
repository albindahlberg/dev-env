#!/usr/bin/env bash
# Tag MLflow traces with `repo` (owner/name from the git origin), so traces
# can be sliced per project. The mlflow-tracing plugin only records the raw
# working directory, which splits one repo across its worktrees and
# subdirectories.
#
# Also tags every trace (codex too) with OTel GenAI agent attributes
# (https://github.com/open-telemetry/semantic-conventions-genai):
# gen_ai.operation.name, gen_ai.provider.name, gen_ai.response.model (model of
# the final LLM call), gen_ai.conversation.id, gen_ai.agent.name. Keys
# mlflow-subagent-stop.sh already set on a subagent trace are left alone.
#
#   mlflow-tag-repo.sh             Stop hook: reads the hook JSON on stdin and,
#                                  in the background, tags this session's traces
#   mlflow-tag-repo.sh --backfill  tag every untagged trace in the experiment
set -uo pipefail

URI="${MLFLOW_TRACKING_URI:-http://localhost:5000}"
API="$URI/api/2.0/mlflow"
EXP_NAME="${MLFLOW_EXPERIMENT_NAME:-agent-traces}"

repo_of() { # repo_of <dir>
  local d=$1 url common
  case $d in
    */.claude/worktrees/*) d=${d%%/.claude/worktrees/*} ;; # claude worktree -> its parent checkout
  esac
  while [ ! -d "$d" ]; do d=$(dirname "$d"); done # worktree may be gone since
  if url=$(git -C "$d" remote get-url origin 2>/dev/null); then
    url=${url%.git} url=${url%/}
    url=${url#*://} url=${url#*@} url=${url#*[:/]} # drop scheme, user, host
    printf '%s' "$url"
  elif common=$(git -C "$d" rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then
    basename "$(dirname "$common")"
  else
    basename "$d" # not a repo (or a deleted herdr worktree: .herdr/worktrees/<repo>/...)
  fi
}

set_tag() { # set_tag <trace-id> <key> <value>
  curl -fsS -o /dev/null -X PATCH "$API/traces/$1/tags" -H 'Content-Type: application/json' \
    -d "$(jq -nc --arg k "$2" --arg v "$3" '{key: $k, value: $v}')"
}

tag_genai() { # tag_genai <trace-id> <session> <has-agent-name>
  local model provider name
  model=$(curl -fsS -G "$URI/ajax-api/2.0/mlflow/get-trace-artifact" --data-urlencode "request_id=$1" |
    jq -r '[.spans[] | select(.attributes["mlflow.spanType"] == "LLM") | .attributes.model // empty] | last // empty') || return
  [ -n "$model" ] || return # no LLM span yet, retry on the next pass
  case $model in
    claude*) provider=anthropic name=claude-code ;;
    gpt* | o[0-9]*) provider=openai name=codex ;;
    *) provider=unknown name=unknown ;;
  esac
  set_tag "$1" gen_ai.response.model "$model"
  set_tag "$1" gen_ai.provider.name "$provider"
  [ -n "$2" ] && set_tag "$1" gen_ai.conversation.id "$2"
  if [ "$3" = false ]; then # not a subagent trace
    set_tag "$1" gen_ai.agent.name "$name"
  fi
  set_tag "$1" gen_ai.operation.name invoke_agent # last: marks the trace done
  echo "$1 $model"
}

tag_traces() { # tag_traces <filter>
  local exp_id token="" page id wd repo
  exp_id=$(curl -fsS -G "$API/experiments/get-by-name" --data-urlencode "experiment_name=$EXP_NAME" |
    jq -r '.experiment.experiment_id // empty') || return
  [ -n "$exp_id" ] || return
  declare -A cache
  while :; do
    page=$(curl -fsS -G "$API/traces" --data-urlencode "experiment_ids=$exp_id" \
      --data-urlencode "filter=$1" --data-urlencode max_results=500 --data-urlencode "page_token=$token") || return
    # \x1f, not tab: read collapses runs of whitespace IFS, shifting empty fields
    while IFS=$'\x1f' read -r id wd session has_repo has_genai has_name; do
      if [ "$has_repo" = false ] && [ -n "$wd" ]; then # codex traces carry no working directory
        [ -n "${cache[$wd]+x}" ] || cache[$wd]=$(repo_of "$wd")
        repo=${cache[$wd]}
        set_tag "$id" repo "$repo"
        echo "$id $repo"
      fi
      [ "$has_genai" = false ] && tag_genai "$id" "$session" "$has_name"
    done < <(jq -r '.traces[]
      | (.tags // [] | map(.key)) as $t
      | select(($t | index("repo") | not) or ($t | index("gen_ai.operation.name") | not))
      | ((.request_metadata // []) | from_entries) as $m
      | [.request_id, ($m["mlflow.trace.working_directory"] // ""), ($m["mlflow.trace.session"] // ""),
         ($t | index("repo") != null), ($t | index("gen_ai.operation.name") != null), ($t | index("gen_ai.agent.name") != null)]
      | map(tostring) | join("\u001f")' <<<"$page")
    token=$(jq -r '.next_page_token // empty' <<<"$page")
    [ -n "$token" ] || break
  done
}

if [ "${1:-}" = --backfill ]; then
  tag_traces ""
  exit 0
fi

session=$(jq -r '.session_id // empty' 2>/dev/null)
[ -n "$session" ] || exit 0
# the plugin's Stop hook writes this turn's trace concurrently; wait it out
# detached so the turn never blocks. Traces missed here get tagged next Stop.
(sleep 20; tag_traces "request_metadata.\`mlflow.trace.session\` = '$session'") >/dev/null 2>&1 &
disown
exit 0
