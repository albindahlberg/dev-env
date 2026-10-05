#!/usr/bin/env bash
# Render Markdown from stdin in the browser via markdown-preview.nvim.
# One file, server and port per agent session, so parallel agents never
# overwrite each other's preview. Always opens a tab: the plugin's own
# browser launch is unreliable under WSL.
set -euo pipefail

sid=${CLAUDE_CODE_SESSION_ID:-default}
f=/tmp/show-me/$sid.md
# ponytail: hashed port can collide between two sessions; that preview then fails to start
port=$((8422 + $(printf %s "$sid" | cksum | cut -d' ' -f1) % 500))
u=http://localhost:$port/

mkdir -p /tmp/show-me
cat >"$f"

if ! pgrep -f "^nvim --headless $f" >/dev/null; then
  nohup timeout 30m nvim --headless "$f" \
    -c 'set autoread' \
    -c 'call timer_start(1000, {-> execute("checktime")}, {"repeat": -1})' \
    -c "lua require('markdown_preview').setup({ instance_mode = 'multi', port = $port, open_browser = false })" \
    -c MarkdownPreview >/dev/null 2>&1 &
  for _ in $(seq 50); do curl -s -o /dev/null "$u" && break; sleep 0.1; done
fi

# wslview goes through PowerShell, which fails under Constrained Language Mode.
# stderr stays visible so a failed launch isn't reported as "opened".
if grep -qi microsoft /proc/version; then
  (cd /mnt/c && cmd.exe /c start "" "$u") >/dev/null
elif [ "$(uname)" = Darwin ]; then
  open "$u"
else
  xdg-open "$u" >/dev/null
fi || echo "could not open a browser tab; open $u manually" >&2

echo "$f -> $u"
