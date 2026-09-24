---
name: config-sync
description: 'Audit this machine''s agent-tool configs (claude, codex, pi, opencode, and any other CLI under ~/.<tool> or ~/.config/<tool>) against this repo (dev-env) to find skills or hooks that exist live but aren''t tracked yet, then fold them in — move the real file into the repo under the right place and symlink the live path(s) back to it. Use when the user wants to sync configs, audit dotfiles, catch drift between machines, or find local-only skills/hooks not yet in the repo. Trigger: "sync configs", "audit dotfiles", "sync skills to repo", "check for local skills/hooks", or /config-sync.'
---

Read `AGENTS.md` first — it's the pattern this skill applies. The short version: real files live in this repo under `skills/<category>/<name>/` or `hooks/<name>`; each tool's own dir (`claude/`, `codex/`, ...) holds symlinks back into them.

## Hard constraint

**Never read, diff, cat, move, or otherwise touch anything outside a tool's `skills` and `hooks` subdirectories (see the table below for where those are per tool), plus any hook files already known to live at a tool's root (e.g. `~/.codex/herdr-agent-state.sh`).** Everything else — credentials, auth tokens, history, sessions, sqlite/log files, `config.toml`, `settings.json`, `models-store.json`, `run-history.jsonl`, caches, `projects/`, `tasks/`, `teams/`, `memories*` — is out of scope by construction. Don't `ls -la` or `find` the rest of a tool's config dir looking for "more to sync"; don't open anything there even to check if it's secret. If a candidate in an in-scope dir turns out to reference or embed something that looks like a credential, stop and flag it instead of moving it.

When probing a tool you don't have a table entry for yet (e.g. a new CLI), only look for a directory literally named `skills` or `hooks` (case-insensitive) up to two levels below its config root — don't go browsing the rest of its config tree to figure out its layout. If you can't find one confidently, ask the user instead of guessing.

## Known tools

| Tool | Root | Skills | Hooks | Notes |
|---|---|---|---|---|
| claude | `~/.claude` | `skills/*` | `hooks/*` | file-by-file symlinks into repo `claude/` |
| codex | `~/.codex` | `skills/*` | `hooks/*`, plus root-level hook files like `herdr-agent-state.sh` | file-by-file symlinks into repo `codex/` |
| pi | `~/.pi` | `agent/skills/*` | none known | `~/.pi` is one symlink to repo `pi/` as a whole (not file-by-file) — see pi note below |
| opencode | `~/.config/opencode` or `~/.opencode`, whichever exists | probe for it | probe for it | not set up on this machine as of writing; check both roots, skip entirely if neither exists |

If a tool's root doesn't exist on this machine, skip it silently — don't create it.

**pi is structurally different**: `~/.pi` already *is* `pi/` in the repo (one whole-directory symlink from `install.sh`), so there's no "live copy vs repo copy" to reconcile — anything under `~/.pi/agent/` is already physically inside the repo. `pi/.gitignore` blanket-ignores `agent/*` except `agent/settings.json`, so real (non-symlink) entries under `agent/skills/` are sitting there untracked, not migrated. To promote one: it's already in the right place content-wise, but check whether it should actually move into the shared `skills/<category>/<name>/` scheme (so claude/codex can use it too) with `pi/agent/skills/<name>` becoming a symlink into it — if so, follow the normal move+link steps below, then add the narrowest `!agent/skills/<name>` (and any needed parent un-ignore lines) to `pi/.gitignore` and confirm with `git check-ignore -v` that it's no longer ignored before `git add`.

## Audit

For each known tool whose root exists, list `<root>/<skills-path>/*` and `<root>/<hooks-path>/*`:

- Already a symlink pointing into `$REPO/...`? Synced, skip it.
- A symlink pointing somewhere else (e.g. `../../../../../.agents/skills/<name>`, a marketplace/plugin symlink)? Not ours to manage, skip it.
- A real file/dir, not a symlink? That's a candidate — something local that isn't in the repo yet.

For a candidate name that exists under more than one tool, `diff -rq` the copies:
- Identical → one candidate, any copy is the source.
- Differ → don't silently pick one. Surface the diff and ask the user which is canonical (or whether it's actually two intentionally-different things, e.g. codex's `herdr-agent-state.sh` vs claude's, which look similar but are tool-generated and genuinely differ).

For a candidate that exists under only one tool, that tool's copy is the source; it gets symlinked into the other tools that make sense for it too, unless the user says it should stay tool-specific.

## Placing a candidate

- **Skill**: pick a category. If its description clearly fits an existing one (`skills/github/`, `skills/git/`, `skills/workflow/`, `skills/dotfiles/`, ...), use it. If it doesn't, ask the user to name a category or confirm a new one — don't invent one silently, and don't pre-create empty categories for anything else while you're at it (YAGNI, per `AGENTS.md`).
- **Hook shared identically across the tools that have it**: `hooks/<name>`, symlinked from each tool's `<tool>/hooks/<name>`.
- **Hook that's genuinely tool-specific** (like the herdr hooks — same purpose, different generated content per tool): stays under `<tool>/hooks/<name>` (or `<tool>/<name>` if that's where it actually lives, like codex's root-level herdr hook) directly, not promoted to the shared `hooks/` dir.
- Before moving anything, check whether it's a duplicate of an installed marketplace plugin for that tool (same trigger phrases / near-identical description) — skip importing it if so, same as the existing github/git/workflow skills were vetted.

## Move and link

1. `git mv` (tracked) or `mv` + `git add` (untracked) the real file into its repo location. For pi, it's typically already inside the repo (see pi note above) — this step may just be `git mv` within the repo tree, no filesystem move to/from `~/.pi`.
2. Symlink the live path(s) back with `ln -sfn <abs-repo-path> <live-path>` for every tool that should have it — except pi, where the symlink you create at `pi/agent/skills/<name>` (relative, into `../../skills/<category>/<name>`) is *inside* the repo and needs no separate live-side `ln`, since `~/.pi` already resolves there through the existing whole-dir link.
3. Skills for claude/codex are picked up automatically by `install.sh`'s `for s in "$REPO"/skills/*/*/` loop — no edit needed there. Hooks aren't wildcarded: add an explicit `link "$REPO/..." "$HOME/..."` line in `install.sh`'s `install_links`, following the existing lines right above it as the pattern. A brand-new tool needs its own linking added to `install_links` the same way claude/codex/pi are — follow whichever existing tool's shape is the closer match (file-by-file like claude/codex, or whole-dir like pi).
4. Run `./install.sh --dry-run --no-packages` afterward and confirm every touched path prints `ok` (idempotent, nothing left dangling).
5. Update the relevant `README.md` (`claude/README.md`, `codex/README.md`, root `README.md`) and `AGENTS.md` only if the change adds a new category or a new kind of exception (like the tool-specific-hook carve-out) — a same-shape addition to an existing category needs no doc edit.

Report what moved and where before finishing; don't commit unless asked.
