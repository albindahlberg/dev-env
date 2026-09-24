---
name: skewer
description: 'Grill the user relentlessly about a plan, decision, or idea, but ask every question through the interactive AskUserQuestion picker (arrow-key select or free text) instead of a plain-text block. Use when the user wants to stress-test their thinking with quick pick-one-of-N answers, says "skewer me/this", or asks for an interactive/pickable version of grilling. Trigger: "skewer", "skewer me", "skewer this", or /skewer.'
---

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled: the questions you can ask _now_ without guessing at answers you haven't heard yet.

Ask the whole frontier in one round using the **AskUserQuestion** tool:

- One frontier question → one entry in the `questions` array.
- `header`: a short topic label (≤12 chars), not "Q1".
- `question`: the full question, with any needed context folded in.
- `options`: 2-4 mutually exclusive concrete answers. Put your recommended answer **first** and append "(Recommended)" to its label. Use each option's `description` for the reasoning/tradeoff behind it. A free-text "Other" is always available to the user automatically — never add your own "other" option.
- `multiSelect`: leave `false` unless the decision is genuinely non-exclusive (rare in a design tree).
- The tool caps at 4 questions per call and 4 options per question. If the frontier has more than 4 questions, split it across multiple sequential AskUserQuestion calls — that's still one round.
- If a frontier question doesn't reduce to 2-4 concrete options (pure open-ended fact-finding from the user, or its answer space is unbounded), ask it as plain text instead of forcing it into the tool — don't distort the question to fit the picker.

Each round the user answers reshapes the tree: settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one.

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, etc.), dispatch a sub-agent to find it; don't ask the user for anything you could look up yourself. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report; ask the rest of the frontier now. The _decisions_ are the user's: put each to them via the picker and wait.

The session is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed. Do not act on it until the user confirms you have reached a shared understanding.
