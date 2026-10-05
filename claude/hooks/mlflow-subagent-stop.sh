#!/usr/bin/env bash
# SubagentStop -> MLflow trace. The mlflow-tracing plugin only hooks Stop, so
# background subagents (whose transcripts finish after the parent turn) never
# get traced. Reuse the plugin's own stop.cjs, pointed at the subagent's
# transcript instead of the parent's, then tag the trace with OTel GenAI agent
# attributes (same keys as mlflow-tag-repo.sh). Only subagent traces carry
# gen_ai.agent.id, so filter subagent spend on that. No-op when the plugin
# isn't installed.
set -euo pipefail

stop_cjs="$(ls -1d "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"/plugins/cache/mlflow-plugins/mlflow-tracing/*/bundle/stop.cjs 2>/dev/null | sort -V | tail -1 || true)"
[[ -n "$stop_cjs" ]] || exit 0

STOP_CJS="$stop_cjs" node -e '
const fs = require("fs"), os = require("os"), path = require("path");
const { execFileSync } = require("child_process");
let b = "";
process.stdin.on("data", d => (b += d)).on("end", async () => {
  const i = JSON.parse(b);
  if (!i.agent_transcript_path || !fs.existsSync(i.agent_transcript_path)) return;

  // The plugin traces from the last plain user message on. In a subagent that
  // is usually an injected <system-reminder>, which hides the real task
  // prompt, so drop reminder-only user entries from a temp copy.
  const isReminder = e => e.type === "user" && !e.toolUseResult &&
    typeof e.message?.content === "string" && e.message.content.trimStart().startsWith("<system-reminder>");
  const entries = fs.readFileSync(i.agent_transcript_path, "utf8").split("\n").filter(Boolean)
    .map(l => JSON.parse(l)).filter(e => !isReminder(e));
  const lastUser = [...entries].reverse().find(e => e.type === "user" && !e.toolUseResult && !e.isCompactSummary);
  const model = [...entries].reverse().find(e => e.type === "assistant" && e.message?.model)?.message.model;
  const tmp = path.join(fs.mkdtempSync(path.join(os.tmpdir(), "mlflow-sub-")), "agent-" + (i.agent_id || "x") + ".jsonl");
  fs.writeFileSync(tmp, entries.map(e => JSON.stringify(e)).join("\n") + "\n");

  try {
    execFileSync("node", [process.env.STOP_CJS], { input: JSON.stringify({ ...i, transcript_path: tmp }), stdio: ["pipe", "ignore", "inherit"] });
  } finally {
    fs.rmSync(path.dirname(tmp), { recursive: true, force: true });
  }

  // Find the trace just written: same parent session + start time of the
  // traced user message. ponytail: ms-timestamp match, two subagents
  // starting in the same ms would both get tagged by whichever stops first.
  const uri = process.env.MLFLOW_TRACKING_URI, name = process.env.MLFLOW_EXPERIMENT_NAME;
  const ts = lastUser?.timestamp && Date.parse(lastUser.timestamp);
  if (!uri || !name || !ts) return;
  const exp = await (await fetch(`${uri}/api/2.0/mlflow/experiments/get-by-name?experiment_name=${encodeURIComponent(name)}`)).json();
  const q = new URLSearchParams({
    experiment_ids: exp.experiment.experiment_id, max_results: "5",
    filter: `request_metadata.\`mlflow.trace.session\` = \x27${i.session_id}\x27 AND trace.timestamp_ms = ${ts}`,
  });
  const { traces = [] } = await (await fetch(`${uri}/api/2.0/mlflow/traces?${q}`)).json();
  const tags = {
    "gen_ai.agent.name": i.agent_type || "unknown",
    "gen_ai.agent.id": i.agent_id || "",
    "gen_ai.conversation.id": i.session_id,
    ...(model && { "gen_ai.response.model": model, "gen_ai.provider.name": "anthropic" }),
    "gen_ai.operation.name": "invoke_agent", // last: tells mlflow-tag-repo.sh this trace is done
  };
  for (const t of traces)
    for (const [key, value] of Object.entries(tags))
      await fetch(`${uri}/api/2.0/mlflow/traces/${t.request_id}/tags`, {
        method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ key, value }),
      });
});'
