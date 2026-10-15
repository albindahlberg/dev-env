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

- No match for a state other than done: create it as `agent:<state>` (`gh label create`).
  Same for a workflow label a skill names (`intent`, `spec`).
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

### Title

Short, specific, states the problem or goal, not the solution.
No trailing period. Bad: `bug`, `doesn't work`. Good: `login redirect loops on expired session`.

### Body

Concise, clear, scannable. Reader should grasp it in 30s. No filler, no blame,
no speculation presented as fact.

No fixed headings; shape the body to what this issue needs.

Visuals: call the Skill tool for `show-me` and add one only where the reader
would otherwise have to rebuild a picture in their head from prose. Pick its
smallest fitting shape:
- **Table** - expected vs actual per case, options compared, affected versions.
- **Flow / sequence / state (Mermaid)** - where the bug happens or how today's
  flow works across components.
- **Call or file tree, or a `diff` on one** - where a change lands.
- **Code block** - exact error text, command, or minimal snippet. Trim logs.

Skip it when one or two sentences say the same thing. In the issue body,
write Mermaid source (GitHub renders it); in chat drafts, render per
`show-me`. Inline Markdown only: no HTML files or previews in an issue.

Rules:
- no empty sections; drop headings with nothing to say
- search for duplicates first (`gh issue list --search`) and link related issues
- one problem per issue; split unrelated asks
- reference the fix with `Closes #123` in the PR, not the issue
- no secrets, tokens, or private data in logs or screenshots

### Scope changes

A decision that narrows, widens or pivots an issue's scope, wherever it is
made (grilling, a comment, a sub-issue, an ADR), is edited into the body of
every issue it changes, the parent intent included. Strike the old line
(`~~old~~`), add the new one beside it, and link the comment or ADR that
holds the why. The body states the current scope; comments hold the history.
