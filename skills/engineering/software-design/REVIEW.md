# Review

A review runs in fresh context, so it judges the code rather than the
reasoning that produced it.

1. **Scope** the diff: the target given (PR, branch, path), else
   `git diff <base>...HEAD` against the merge base.
2. **Dispatch** one `general-purpose` subagent per lens, in parallel in
   one message. Each reads only its own brief, so its attention stays on
   one kind of problem:
   - [REVIEW-BOUNDARIES.md](REVIEW-BOUNDARIES.md): the touched modules
     whole: what each exposes, who imports what, where rules live, and
     the repo's boundary rules.
   - [REVIEW-CODE.md](REVIEW-CODE.md): the changed code: naming,
     documentation, readability and, with a spec, its interface and
     requirement IDs.

   Leave out the builder's plan and reasoning. Each gets this prompt,
   filled in:

   ```
   Read <this skill's directory>/<brief> and follow it.
   Repo: <path>
   Target: <diff target>
   Repo docs: <paths to AGENTS.md / CLAUDE.md, ADRs, review guides>
   Spec issue: #<N>   (only when the work has one)
   ```
3. **Report** the hits, mechanical first, then judgement. Boundary-lint
   proposals go last, as questions for the user. Posted to a PR, hits
   follow `conventional-comments`.
