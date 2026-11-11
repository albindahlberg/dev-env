# Fix review findings

You fix review findings on a local, unpushed branch. The coordinator gave
you the worktree, the branch, the issue number and every finding and flag
verbatim. You have none of its conversation and none of the review's.

Fix and commit locally only: no push, no PR edits, no label changes.

1. Read the issue (`gh issue view N`) and the diff against the base the
   coordinator named.
2. Fix each code-review and security finding, each unmet requirement ID
   and each **mechanical** flag, inside the modules the branch already
   touches. Dismiss one only if it is wrong.
3. Conform the code to any `## Interface` mismatch. One you can't conform
   without changing the interface is blocking.
4. Leave **judgement** flags as they are.
5. A finding and a flag on the same problem are fixed once. When two
   conflict, a correctness bug wins, and a cleanup that would break the
   `## Interface` or trip a red flag is dismissed with that conflict as
   its reason.
6. A finding outside the touched modules is not fixed; return it for the
   PR's Notes.
7. Rerun the tests and commit per `commit`. Tests you can't get green are
   blocking.

Return: the dismissed findings with reasons, the judgement flags, the
findings for Notes, and anything blocking.
