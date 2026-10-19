---
name: pr
description: Write pull request titles and descriptions. Use whenever creating or updating a PR (gh pr create/edit) or drafting PR text, unless the repo root has a .pr_agent.toml.
---

# PR

Skip this skill if `.pr_agent.toml` exists in the repo root. PR-Agent writes
the title and description there, so leave them to it.

Title: MUST use a conventional prefix: `type(scope)?: description`
(`feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert`, see
`commit`). Lowercase, imperative, no trailing period, <= 70 chars.
Type = dominant change of the PR, matching its branch (`worktree`).
Examples: `feat(herdr): add target picker`, `fix(auth): refresh expired token`.
Never open or edit a PR with an unprefixed title.

## Template first

Before writing the body, look for a PR template in the project root:
`.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE.md`,
`docs/pull_request_template.md`, `pull_request_template.md`, or any file in
`.github/PULL_REQUEST_TEMPLATE/` (multiple: pick the best fit, ask if unclear).

- Found: fill it in, keep its headings and order, don't invent sections.
  Delete HTML comments and placeholder text. Tick only checkboxes that are true.
  The concise/table/diagram rules below apply *inside* its sections.
- Not found: no fixed headings; shape the body to what this change needs.
- Title prefix rule always applies, template or not.

Body: concise, clear, scannable. Reviewer should grasp the change in 30s.
No filler, no restating the diff line by line, no marketing tone.

Visuals, two steps:
1. Always call the Skill tool for `show-me` before drafting the body, even
   when you expect no visual.
2. Then decide. Required when the change alters a flow, schema, data shape
   or order of steps. Otherwise add one only where the reviewer would have
   to rebuild a picture from prose, and skip it if prose is clearer. Pick the
   smallest view (pseudocode, call tree, component tree, file tree, Mermaid,
   `diff` of shape, table for before/after or many options). Reuse a visual
   from the linked issue or spec when one fits. Inline Markdown only; no
   HTML files or previews in a PR body.

Rules:
- no empty sections; drop headings that have nothing to say
- link issues with `Closes #123`
- don't paste full diffs or file lists the PR UI already shows
- end with the attribution line required by the session, if any
