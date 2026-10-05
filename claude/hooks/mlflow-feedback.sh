#!/usr/bin/env bash
# UserPromptSubmit hook: turn prompts into MLflow feedback on the session's
# latest trace (the previous turn).
#
#   +1 [note] / -1 [note]   log `user_rating` true/false and swallow the
#                           prompt, so it never reaches the model
#   no / wrong / revert...  log `corrected` = true, prompt goes through as usual
set -uo pipefail

URI="${MLFLOW_TRACKING_URI:-http://localhost:5000}"
EXP_NAME="${MLFLOW_EXPERIMENT_NAME:-agent-traces}"

input=$(cat)
prompt=$(jq -r '.prompt // empty' <<<"$input")
session=$(jq -r '.session_id // empty' <<<"$input")
[ -n "$session" ] || exit 0

shopt -s nocasematch
if [[ $prompt =~ ^([+-])1([[:space:]]+(.*))?$ ]]; then
  name=user_rating value=$([ "${BASH_REMATCH[1]}" = + ] && echo true || echo false)
  note=${BASH_REMATCH[3]}
  rating=1
# ponytail: prefix regex, misses corrections phrased any other way; an LLM judge over prompts if this undercounts
elif [[ $prompt =~ ^(no|nope|wrong|revert|undo|not\ what|that\'?s\ not|that\ is\ not|try\ again|don\'?t)([^a-z]|$) ]]; then
  name=corrected value=true note=${prompt:0:300} rating=0
else
  exit 0
fi

reply() { # swallow a rating prompt, telling the user what happened
  [ "$rating" = 1 ] && jq -nc --arg r "$1" '{decision: "block", reason: $r}'
  exit 0
}

exp_id=$(curl -fsS -G "$URI/api/2.0/mlflow/experiments/get-by-name" --data-urlencode "experiment_name=$EXP_NAME" |
  jq -r '.experiment.experiment_id // empty') || reply "mlflow: server unreachable at $URI, rating not logged"
trace=$(curl -fsS -G "$URI/api/2.0/mlflow/traces" --data-urlencode "experiment_ids=$exp_id" \
  --data-urlencode "filter=request_metadata.\`mlflow.trace.session\` = '$session'" \
  --data-urlencode "order_by=timestamp_ms DESC" --data-urlencode max_results=1 |
  jq -r '.traces[0].request_id // empty')
[ -n "$trace" ] || reply "mlflow: no trace for this session yet, rating not logged"

body=$(jq -nc --arg t "$trace" --arg n "$name" --argjson v "$value" --arg r "$note" --arg u "${USER:-user}" \
  '{assessment: ({trace_id: $t, assessment_name: $n, source: {source_type: "HUMAN", source_id: $u},
     feedback: {value: $v}} + (if $r == "" then {} else {rationale: $r} end))}')
if curl -fsS -o /dev/null -X POST "$URI/api/3.0/mlflow/traces/$trace/assessments" \
  -H 'Content-Type: application/json' -d "$body"; then
  reply "mlflow: logged $name=$value on $trace"
fi
reply "mlflow: failed to log $name on $trace"
