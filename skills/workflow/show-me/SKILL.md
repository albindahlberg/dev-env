---
name: show-me
description: Help the user understand the current topic visually with concise diagrams and code-shape sketches, shown in a rendered Markdown preview. Use when explaining flow, structure, or a change visually, or when the user says "show me", "in md", "w md", "md preview", "markdown preview", "show me in preview", or "in a pane".
---

Help the user understand the current topic of conversation visually. Skip the preamble and keep prose brief. Pick the smallest view that makes the key point clear, and place each visual next to the short text it supports.

Everything is written as Markdown, with diagrams as raw ` ```mermaid ` blocks. The terminal does not render Mermaid, so the Markdown goes somewhere that does.

## Where it goes

Take the first that applies:

1. **Another skill is writing a GitHub body or a repo file** (PR, issue, doc): the visual goes inline in that text. Open the preview only when the user is asked to review the draft.
2. **The user asked for the terminal** ("in here", "in chat"): answer in the reply with the text shapes below and no Mermaid.
3. **The user asked for "in a pane" or "in a split"**: see [Pane](#pane).
4. **Otherwise: the Markdown preview.** This is the default.

## Shapes

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

- A change as a `diff` on whichever of these shapes fits the topic:

```diff
 submitForm
   createSession
     persistPrompt
+    expandSkillMention
     launchAgent
```

- The whole block when most of it is new or the user needs a copyable target.

- Flow between components, a sequence, states or dependencies as Mermaid (`graph TD/LR`, `sequenceDiagram`, `stateDiagram-v2`). Write one edge per line, label edges with `-->|label|`, and split a diagram whose edges cross into smaller ones.

- Options or before/after compared as a table.

## Preview

Pipe the Markdown into `preview.sh`, which renders it with mdkite.nvim, from this skill's base directory. Run it every time, including for updates: it rewrites this session's file, starts this session's server if needed, and opens a browser tab. Each session has its own file and port, so parallel agents never overwrite each other.

```
Bash(cat <<'EOF' | <skill-dir>/preview.sh
# Title
...
EOF)
```

For a file that already exists, such as a repo doc: `<skill-dir>/preview.sh < docs/x.md`. If the file belongs in the repo (a doc, a future issue), write it there and preview a copy.

Once a preview is open in this conversation, keep updating it.

In the reply, say in one or two lines what the preview shows. Leave the document itself in the preview.

If it prints "could not open a browser tab", say so and give the URL.

## Pane

Write the Markdown to a file and run `"$(dirname "$(readlink ~/.config/herdr/config.toml)")/peek.sh" <file>`. It opens the file in nvim to the right of this pane, rendered by render-markdown.nvim; once that pane is open, later calls load the file into it instead of splitting again, so run it for every update, including rewrites of the same file. With no file it opens the working-tree diff in diffview.nvim.

## HTML: rare

For a visual UI mockup or layout comparison that Markdown cannot show, write one focused HTML file with real labels and data. Open it with `cmd.exe /c start` on WSL (run from `/mnt/c`, pass `$(wslpath -w "$f")`), `open` on macOS, `xdg-open` on Linux.
