---
name: intent
description: 'Capture a problem as an intent: grill the originator on the problem space (no solutions), then file it as a GitHub issue that becomes the parent for spec sub-issues. Stage 1 (Plan) of the AI-native SDLC. Use when the user has an idea, request, or problem to write up before any design. Trigger: "intent", "write an intent", "capture this idea", or /intent.'
---

# Intent

Stage 1 of intent -> spec -> build. Output: one issue whose body is the intent,
a proto-spec in the originator's own terms: what is wanted, why, and under
which constraints. One intent becomes one PR stack, so it scopes one change.
Next stage is the `spec` skill.

The intent is also where `spec`'s strategic design starts: where this area
already hurts, and what is likely to follow, tell `spec` how much design
investment the change deserves.

1. **Grill** - call the Skill tool for `skewer` (grilling via the
   AskUserQuestion picker), asking as an analyst: scope, users,
   constraints, success. The design tree is limited to these five
   sections:
   - **Problem** - what can't be done today, who hurts, how much, in the
     words of the people who hurt. Include known pain: what keeps breaking
     here, or is slow or risky to change. Class names, constants, data
     paths, branches and files belong to `spec`.
   - **Proposed outcome** - what better looks like, observable; a task
     list (`- [ ]`), one box per outcome.
   - **Affected users and systems** - people, teams, services, repos.
   - **Constraints** - must/must-not (security, data, compliance), plus
     what's out of scope. Mark each out-of-scope item that's likely needed
     later as **later**; `spec` sizes module interfaces for those.
   - **Open questions** - what's still unknown about the problem; fine to
     leave some.

   Problem space only. If an answer proposes a solution, record the need
   behind it as an outcome or constraint and park the solution for `spec`.
   Look up facts (existing issues, code, docs, co-change history behind a
   known pain) yourself; only ask the user for decisions and context they
   alone have.

2. **Confirm** - draft the body to about 250 words, a 30-second read; over
   budget, cut mechanism and solution detail first. Call the Skill tool for
   `show-me` and add a visual wherever it reads faster than prose: today's
   workflow, the users and systems involved, where the pain sits, or the
   user's experience before and after. Visuals show the problem. In chat,
   render per `show-me`; in the issue body use the Mermaid source (GitHub
   renders it). Show it and let the originator correct anything misread;
   wait for an explicit yes.

3. **File** - per the `issue` skill's writing rules (duplicate search),
   with this body structure:

   ```md
   ## Problem
   ## Proposed outcome
   ## Affected users and systems
   ## Constraints
   ## Open questions
   ```

   Title: what the intent wants, as a short imperative, with no prefix:
   `Switch the webapp to the production Keycloak client`, not `Staff can't
   sign in on dev`. Name the goal, not its mechanism; the body holds the
   problem. Label it `intent`.

4. **Hand off** - report the issue link; the next step is `/spec #N`.

The body always states the current intent. Later narrowing or pivots are
scope changes, edited in per the `issue` skill.
