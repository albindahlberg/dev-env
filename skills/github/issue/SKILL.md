---
name: issue
description: Handle GitHub issues. Use whenever interacting with a gh issue - creating, editing, reading, commenting, labeling, or implementing one (gh issue ...), or drafting issue text.
---

# Issue

Two parts: **Working an issue** (lifecycle labels when an agent implements it)
and **Writing an issue** (title/body standards).

## Working an issue

Applies whenever an agent is asked to implement, fix, or pick up an issue.

### 1. Discover status labels

Never assume label names. Run `gh label list --limit 100` (or
`gh label list --search agent`) and map the repo's labels to these states,
preferring the `agent:` family, then close synonyms:

| State | Preferred | Accept (case-insens.) |
|---|---|---|
| ready | `agent:ready` | `ready`, `status:ready`, `ready for dev`, `good first agent` |
| working | `agent:working` | `in progress`, `status:in-progress`, `wip`, `doing` |
| review | `agent:review` | `needs review`, `in review`, `status:review`, `ready for review` |
| blocked | `agent:blocked` | `blocked`, `needs info`, `status:blocked` |
| done | `agent:done` | `status:done` (usually closed by PR merge instead - don't add) |

- No match for a state: skip it silently. Don't create labels unless the user asks.
  Mention once in the final message that the label is missing.
- Never touch labels outside these states (type, priority, area, ...).

### 2. Transitions

| Moment | Do |
|---|---|
| Pick next issue (none named) | `gh issue list --label "agent:ready"`; take the oldest unassigned, or ask if unclear |
| Start work | read issue + comments; check it isn't already `working`/assigned to someone else (if so, stop and ask); swap **ready** -> **working** |
| PR opened | swap **working** -> **review**; comment with the PR link; PR body has `Closes #N` |
| Blocked / need input | post a **blocked comment** (below), then swap **working** -> **blocked** |
| Unblocked (answer given) | swap **blocked** -> **working**; continue |
| Abandoning / giving up | swap **working** -> **ready** (or remove if none); comment why |
| Review feedback, resuming | swap **review** -> **working**, then back to **review** when pushed |

Commands:
`gh issue edit N --add-label "agent:working" --remove-label "agent:review"`
`gh issue comment N --body "..."`

Blocked comment - post it before changing the label, so the reason is never missing:

```md
**Blocked:** <one line: what stops progress>

Need:
1. <specific question, answerable in a sentence>
2. ...

Tried: <what was checked/attempted, 1 line>
Default if no answer: <assumption the agent will proceed with, if any>
```

- Questions must be concrete and answerable, not "please clarify".
- Search issue, comments, code, and docs first; only ask what they can't answer.
- Tag the issue author or assignee with `@user` if known.
- Then stop work on it and tell the user in the final message what is needed.

Rules:
- **ready** = groomed and queued for an agent; a human sets it; the agent only removes it on start, or restores it when abandoning.
- Issue lacking **ready** but explicitly named by the user: proceed anyway, just add **working**.
- Exactly one state label at a time: always remove the previous one in the same call.
- Never leave `working` stale: on any exit path (done, blocked, error, abandon) update it.
- Comments: one or two lines, no chatter (`Started; branch feat/x. `, `PR: #12`).
- Branch/worktree per `worktree`, PR per `pr`.

## Writing an issue

### Template first

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

### Title

Short, specific, states the problem or goal, not the solution.
No trailing period. Bad: `bug`, `doesn't work`. Good: `login redirect loops on expired session`.

### Body

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
