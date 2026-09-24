#!/usr/bin/env bash
set -euo pipefail

payload="${1:-}"
if [[ -z "$payload" ]]; then
  exit 0
fi

CONFIG_PATH="${HOME}/.codex/mlflow-tracing.json"
EXPERIMENT_NAME="agent-traces"

tracking_uri=""
if [[ -f "$CONFIG_PATH" ]]; then
  tracking_uri="$(node -e 'const fs=require("fs");const p=process.argv[1];try{const c=JSON.parse(fs.readFileSync(p,"utf8"));process.stdout.write(c.trackingUri||"");}catch{}' "$CONFIG_PATH")"
fi

if [[ -n "$tracking_uri" ]]; then
  enc_name="$(node -p 'encodeURIComponent(process.argv[1])' "$EXPERIMENT_NAME")"

  get_resp="$(curl -fsS "${tracking_uri}/api/2.0/mlflow/experiments/get-by-name?experiment_name=${enc_name}" 2>/dev/null || true)"
  exp_id="$(printf '%s' "$get_resp" | node -e 'let b="";process.stdin.on("data",d=>b+=d).on("end",()=>{try{const j=JSON.parse(b);process.stdout.write(j?.experiment?.experiment_id||"")}catch{}})')"

  if [[ -z "$exp_id" ]]; then
    create_payload="$(printf '{"name":"%s"}' "$EXPERIMENT_NAME")"
    create_resp="$(curl -fsS -X POST "${tracking_uri}/api/2.0/mlflow/experiments/create" -H 'Content-Type: application/json' -d "$create_payload" 2>/dev/null || true)"
    exp_id="$(printf '%s' "$create_resp" | node -e 'let b="";process.stdin.on("data",d=>b+=d).on("end",()=>{try{const j=JSON.parse(b);process.stdout.write(j?.experiment_id||"")}catch{}})')"
  fi

  if [[ -n "$exp_id" ]]; then
    export MLFLOW_EXPERIMENT_ID="$exp_id"
  fi
fi

exec mlflow-codex notify-hook "$payload"
