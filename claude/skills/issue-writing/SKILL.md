---
name: issue-writing
description: Write GitHub issue titles and bodies. Use whenever creating or editing an issue (gh issue create/edit) or drafting issue text.
---

# Issue writing

## Template first

Before writing the body, look for an issue template in the project:
`.github/ISSUE_TEMPLATE/*.md|*.yml|*.yaml` (also `config.yml` for blank-issue
rules), `.github/issue_template.md`, `.github/ISSUE_TEMPLATE.md`,
`docs/issue_template.md`, or `issue_template.md`.

- Found: pick the one matching the issue kind (bug, feature, ...), ask if unclear.
  Fill it in, keep its headings and order, don't invent sections.
  Delete HTML comments and placeholder text. Tick only checkboxes that are true.
  For YAML form templates, answer every field in order and carry over the
  template's `title` prefix and `labels` (`gh issue create --template <name>`
  or `--label`).
- Not found: use the default structure below.
- Concise/table/diagram rules below apply *inside* the template's sections.

## Title

Short, specific, states the problem or goal, not the solution.
No trailing period. Bad: `bug`, `doesn't work`. Good: `login redirect loops on expired session`.

## Body

Concise, clear, scannable. Reader should grasp it in 30s. No filler, no blame,
no speculation presented as fact.

Default structure (no template):

**Bug**
1. **Problem** - 1-2 sentences: what's wrong and impact.
2. **Expected vs actual** - two short lines, or a table for several cases.
3. **Repro** - numbered minimal steps, plus env/version if relevant.
4. **Notes** - logs, suspected cause, workaround. Only if useful.

**Feature / task**
1. **Goal** - what and why, 1-2 sentences.
2. **Scope** - checklist of concrete deliverables.
3. **Out of scope / notes** - only if needed.

Use visuals when they beat prose (skip otherwise):
- **Table** - expected vs actual per case, options compared, affected versions.
- **Mermaid diagram** - flow, sequence, or state where the bug or design lives.
- **Code block** - exact error text, command, or minimal snippet. Trim logs.

Rules:
- no empty sections; drop headings with nothing to say
- search for duplicates first (`gh issue list --search`) and link related issues
- one problem per issue; split unrelated asks
- reference the fix with `Closes #123` in the PR, not the issue
- no secrets, tokens, or private data in logs or screenshots
