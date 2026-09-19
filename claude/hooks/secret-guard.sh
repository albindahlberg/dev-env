#!/usr/bin/env bash
# Block secrets from reaching the model. Exit 2 = block, stderr shown to user/Claude.
#   secret-guard.sh tool    PreToolUse: refuse tool calls touching secret files
#   secret-guard.sh prompt  UserPromptSubmit: refuse prompts containing key-like strings
in=$(cat)
case "$1" in
tool)
  # ponytail: regex over the raw tool input, so obfuscated shell (cat $(echo .e)nv) slips
  # through; the sandbox denyRead is the real backstop for Bash.
  args=$(jq -c '.tool_input // {}' <<<"$in")
  if { grep -qE '(^|[/ "'"'"'=])\.env(\.[A-Za-z0-9_-]+)?($|[ "'"'"'/;|&<>)])' <<<"$args" \
       && ! grep -qE '\.env\.(example|sample|template|dist)' <<<"$args"; } \
     || grep -qE '(id_rsa|id_ed25519|\.pem|\.aws/credentials|\.ssh/|\.netrc|\.kube/config)' <<<"$args"; then
    echo "secret-guard: blocked access to a secret file" >&2; exit 2
  fi ;;
prompt)
  p=$(jq -r '.prompt // ""' <<<"$in")
  if grep -qE 'AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9]{36,}|xox[baprs]-[A-Za-z0-9-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|^[A-Z0-9_]*(SECRET|TOKEN|PASSWORD|API_?KEY)[A-Z0-9_]*=.{8,}' <<<"$p"; then
    echo "secret-guard: prompt looks like it contains a secret; not sent. Remove it and resend." >&2; exit 2
  fi ;;
esac
