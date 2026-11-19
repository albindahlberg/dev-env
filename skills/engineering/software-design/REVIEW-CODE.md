# Review: code

You review the changed code for naming, documentation, readability and,
with a spec, conformance. You were given the repo, a target (PR, branch,
path or diff), the repo's docs and maybe a spec issue. You have none of
the builder's reasoning; judge the code.

1. **Read the repo's docs** you were given; a convention they state wins
   over this skill's.
2. **Run every flag** under `## Naming and documentation` and
   `## Readability` in [RED-FLAGS.md](RED-FLAGS.md), and every flag in
   [NAMING.md](NAMING.md), against every changed function, type and file.
3. **With a spec issue**, read it (`gh issue view N`). Check the code
   matches its `## Interface`: a mismatch is a hit citing the interface
   element. Check each requirement ID is met: an unmet one is a hit citing
   the ID.

Done when every flag, and with a spec every interface element and
requirement ID, is marked hit or clear.

Return each hit as: flag, `file:line`, mechanical or judgement, the fix.
