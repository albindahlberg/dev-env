---
name: intent
description: 'Capture a problem as an intent: grill the originator on the problem space (no solutions), then file it as a GitHub issue that becomes the parent for spec sub-issues. Stage 1 (Plan) of the AI-native SDLC. Use when the user has an idea, request, or problem to write up before any design. Trigger: "intent", "write an intent", "capture this idea", or /intent.'
---

# Intent

Stage 1 of intent -> spec -> build. Output: one issue whose body is the intent.
Next stage is the `spec` skill.

1. **Grill** - call the Skill tool for `skewer` (grilling via the
   AskUserQuestion picker), with the design tree limited to these five
   sections:
   - **Problem** - what can't be done today, who hurts, how much.
   - **Proposed outcome** - what's true when this is solved, observable.
   - **Affected users and systems** - people, teams, services, repos.
   - **Constraints** - must/must-not (security, data, deadlines, budget).
   - **Open questions** - what's still unknown; fine to leave some.

   Problem space only. If an answer proposes a solution, record the need
   behind it as an outcome or constraint and park the solution for `spec`.
   Look up facts (existing issues, code, docs) yourself; only ask the user
   for decisions and context they alone have.

2. **Confirm** - show the drafted body and wait for an explicit yes. If
   today's workflow or the systems involved are easier to see than read,
   call the Skill tool for `show-me` and add one current-state visual
   (never a solution). In chat, render per `show-me`; in the issue body
   use the Mermaid source (GitHub renders it).

3. **File** - per the `issue` skill's writing rules (duplicate search,
   template check), except the body uses this structure instead of the
   default feature template:

   ```md
   ## Problem
   ## Proposed outcome
   ## Affected users and systems
   ## Constraints
   ## Open questions
   ```

   Title: the problem, not the solution, with no prefix. Label it `intent`
   (create the label if the repo lacks it).

4. **Hand off** - report the issue link; the next step is `/spec #N`.
