# Worktrees

When working in a git worktree, `cd` into it and stay there for the duration of
the work. Do not operate on a worktree from outside via `git -C ../other` or
relative `../worktree/...` paths.

Reason: the terminal's working directory is the only signal the multiplexer
(herdr) and the statusline have for *which* worktree an agent is in. Operating
from outside leaves that invisible — no observability into where work is
happening.
