---
name: show-me
description: Help the user understand the current topic visually with concise diagrams, code-shape sketches, and a rendered Markdown preview when asked. Use when explaining flow, structure, or a change visually, or when the user says "show me", "in md", "w md", "md preview", "markdown preview", or "nvim mdpreview".
---

Help the user understand the current topic of conversation visually. Skip the preamble and keep prose brief. Pick the smallest view that makes the key point clear, and place each visual next to the short text it supports.

## Default: in the terminal

Answer in the chat with text visuals, which render fine in a terminal:

- Logic as pseudocode:

```text
on(save)
  if content is unchanged
    return cached result
  write new content
```

- Runtime control flow as a call tree, UI as a component tree, layout as a shallow file tree:

```text
submitForm                     src/
  createSession                ├── commands/   # parses user actions
    persistPrompt              └── sessions/   # owns session state
  navigateToSession
```

- Flow between components as a box-and-arrow sketch:

```text
User ──choose──▶ UI ──prompt──▶ Daemon
                 ▲                │
                 └────stream──────┘
```

- A change as a `diff` on whichever of these shapes fits the topic:

```diff
 submitForm
   createSession
     persistPrompt
+    expandSkillMention
     launchAgent
```

- The whole block when most of it is new or the user needs a copyable target.

- A graph with more than a few nodes or edges: write Mermaid (`graph LR/TD` or `sequenceDiagram`) and render it with `mermaid-ascii`. Hand-drawn arrows drift; this does not. Write one edge per line (chains like `A --> B --> C` lay out badly), prefer `graph TD` for branches with `-->|label|` edges, and if the render tangles, split it into smaller diagrams.

```
Bash(mermaid-ascii -f - --max-width 100 <<'EOF'
graph LR
User --> UI --> Daemon --> UI
EOF)
```

The render is not the answer. The user sees at most a collapsed preview of tool output, so a diagram that exists only in the Bash result was never shown. Copy the rendered output verbatim into your reply in a `text` block, in the spot where the Mermaid would have gone. Never redraw, shorten or summarise a render by hand; Mermaid source never appears in the chat either.

If it prints `warning: graph is N columns wide`, the render is too wide to paste. Re-render with `graph TD`, shorter labels, or split it into two diagrams, then paste that. Draw by hand only if `mermaid-ascii` fails or is missing.

Before sending, check: every diagram you rendered is pasted in the reply.

## Markdown preview: only when needed

Before you draw anything, decide terminal or preview:

1. The user asked for markdown: "in md", "w md", "md preview", "markdownpreview", "md file", "in the browser". Preview. This also covers text you already drafted, such as PR bodies or a doc: put that text in the preview. If the file belongs in the repo (a doc, a future issue), write it there and preview a copy.
2. The user asked for the terminal: "in here", "in chat", "show markdown in here". Terminal only.
3. A preview is already open in this conversation: keep updating it.
4. No signal: ask yourself whether the point survives as terminal text. Preview only when it does not: a diagram with many crossing edges, a table too wide for the terminal, or several sections the user will read top to bottom. When in doubt, answer in the terminal and end with one line: "Want it in md preview?"

To preview, pipe the Markdown (Mermaid allowed) into `preview.sh` from this skill's base directory. Run it every time, including for updates: it rewrites this session's file, starts this session's server if needed, and opens a browser tab. Each session has its own file and port, so parallel agents never overwrite each other.

```
Bash(cat <<'EOF' | <skill-dir>/preview.sh
# Title
...
EOF)
```

For a file that already exists, such as a repo doc: `<skill-dir>/preview.sh < docs/x.md`.

If the user asks for it "in a pane" or "in a split", write the Markdown to a file and run `"$(dirname "$(readlink ~/.config/herdr/config.toml)")/peek.sh" <file>` instead. It opens the file in nvim to the right of this pane, rendered by render-markdown.nvim. With no file it opens the working-tree diff in diffview.nvim. The pane can't draw Mermaid, so render each diagram with `mermaid-ascii --max-width <n>` and write the output as a `text` block in its place, where `<n>` is half this pane's width minus 10 (`herdr pane layout --pane "$HERDR_PANE_ID"`). If a diagram still tangles at that width, say so and offer the browser preview for it.

If it prints "could not open a browser tab", say so and give the URL; don't claim the tab opened.

In the chat, give the key visual rendered by `mermaid-ascii` (see above), not the Mermaid source.

## HTML: rare

For a visual UI mockup or layout comparison that Markdown cannot show, write one focused HTML file with real labels and data. Open it with `cmd.exe /c start` on WSL (run from `/mnt/c`, pass `$(wslpath -w "$f")`), `open` on macOS, `xdg-open` on Linux.
