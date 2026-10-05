---
name: conventional-comments
description: Format PR/MR review comments per Conventional Comments (conventionalcomments.org). Use whenever writing, posting, drafting, or rewording a code review comment, reply, or suggestion on a pull request (gh pr review, gh pr comment, gh api .../comments, /code-review --comment), even if the user just says "leave a comment on the PR" or "review this PR".
---

# Conventional Comments

Every review comment on a PR starts with a label so the author knows at a
glance what it is and whether it blocks the merge. Spec:
https://conventionalcomments.org/

## Format

```
<label> [(decorations)]: <subject>

[discussion]
```

- **label**: exactly one, from the table below, lowercase.
- **decorations**: optional, in parentheses, comma-separated.
- **subject**: one line, the point of the comment.
- **discussion**: optional. Why, context, the concrete fix, next steps.

## Labels

| Label | Use for | Blocks by default? |
|-------|---------|--------------------|
| `praise` | something genuinely good (be specific, not "nice") | no |
| `nitpick` | trivial, preference-based | no |
| `suggestion` | proposed improvement; say what and why | depends |
| `issue` | a real problem (bug, security, broken behavior); pair with a suggestion when you have one | yes |
| `todo` | small, necessary change | yes |
| `question` | possible concern you're not sure about | no |
| `thought` | idea sparked by the review, not a request | no |
| `chore` | process task before merge (changelog, run migration, update docs) | yes |
| `note` | FYI for the reader | no |
| `typo` | misspelling | yes |
| `polish` | quality improvement, nothing wrong | no |
| `quibble` | like nitpick | no |

If the repo or team has its own label set (check CONTRIBUTING.md or a PR
template), use that instead.

## Decorations

- `(blocking)` — must be resolved before merge.
- `(non-blocking)` — must not hold up the merge.
- `(if-minor)` — fix only if the change turns out trivial.
- Custom ones are fine when they add signal, e.g. `(security)`, `(perf)`,
  `(test)`, `(ux)`.

Add `(blocking)` / `(non-blocking)` whenever the label alone leaves it
ambiguous — mostly `suggestion` and `question`. Don't decorate `praise` or
`note`; they're never blocking.

## Writing the comment

- Pick the label from what you're actually asking for, not how strongly
  you feel. A style preference is a `nitpick`, not an `issue`.
- Comment on the code, not the person: "this function" not "you forgot".
- Make it actionable. For `issue`/`suggestion`/`todo`, name the fix or a
  GitHub ```` ```suggestion ```` block when it's a few lines.
- One point per comment. Two unrelated concerns → two comments.
- Include at least one `praise` in a full review when something earns it.
- Summary review body (`gh pr review --body`): no label needed on the
  overall verdict, but any concrete point inside it gets one.

## Examples

```
issue (blocking): token is logged in plaintext on refresh failure

`logger.error(resp)` includes the Authorization header. Log `resp.status`
only.
```

```
suggestion (non-blocking): use `Map` here instead of an object

Keys are user IDs (numbers); `Map` avoids the string coercion and makes
`size` O(1).
```

```
question: does this still run when `retries` is 0?

The loop starts at 1, so it looks like it skips the first attempt.
```

```
nitpick: `data` → `orders` would read better
```

```
praise: the table-driven tests make the edge cases very easy to follow
```
