# AGENTS.md

This repo is portable machine config, checked out once per machine and linked
into place by `./install.sh`. The pattern below is what to follow when adding
config for a new agent CLI (claude, codex, ...) or editing what's already
tracked.

## The pattern

1. **The real files live in this repo, not in `~/.claude` or `~/.codex`.**
   `install.sh` replaces the live path with a symlink back into the repo (or,
   for files a tool rewrites at runtime, seeds it once — see below). Never
   edit a skill or hook by editing the live `~/.claude/...` / `~/.codex/...`
   copy directly unless it's already a symlink; edit the repo file and the
   live path picks it up automatically.

2. **Anything shared between agent tools lives at the repo root, not under
   `claude/` or `codex/`.** `skills/` and `hooks/` hold the actual files.
   `claude/skills/<name>` and `codex/skills/<name>` are symlinks into
   `../../skills/<category>/<name>`, same for `claude/hooks/secret-guard.sh`
   and `codex/hooks/secret-guard.sh` → `../../hooks/secret-guard.sh`. One
   skill or hook, two tools, no drift between copies.

   `skills/` is organized by category — `skills/github/`, `skills/git/`,
   `skills/workflow/`, one dir per skill inside. That nesting is a repo-side
   convenience only: neither Claude Code nor Codex reads a categorized skills
   dir, so `claude/skills/*` and `codex/skills/*` stay flat, symlinked by the
   skill's own basename regardless of which category it's filed under.

3. **Tool-specific config stays under that tool's own directory.**
   `claude/scripts/statusline.sh`, `claude/settings.json`, `codex/config.toml`
   — things one tool understands and the other doesn't.

4. **Settings/config files a tool rewrites at runtime are seeded, not
   linked.** `claude/settings.json` and `codex/config.toml` get copied to
   `~/.claude/settings.json` / `~/.codex/config.toml` only if nothing's
   there yet; after that `install.sh` leaves them alone. Symlinking them
   would mean every plugin toggle, project-trust entry, or MCP server the
   tool writes gets committed back into the repo. Keep these seed files
   secret-free and machine-agnostic — no API keys, no per-machine project
   paths, no local tool paths (see `codex/config.toml`'s comment for what got
   deliberately left out).

5. **Machine-local and secret state is never tracked.** History, sessions,
   credentials, caches, logs — see each tool's README for its exclusion list.
   `.gitignore` covers the patterns that would otherwise slip in.

6. **Run `./install.sh --no-packages` after any change that adds a linked
   path.** That means a new skill, hook, or anything else `install_links`
   links. Otherwise the repo file exists but the live `~/.claude/...` /
   `~/.codex/...` path doesn't, and the tool never sees it. The script is
   idempotent: existing links show `ok`, and it never overwrites seeded
   files. Run `--dry-run` first if the target might already hold a real
   file, because `link` moves that file to `<target>.bak.<timestamp>`.

## Adding a new shared skill or hook

- Put the real file under `skills/<category>/<name>/` or `hooks/<name>`. Use
  an existing category (`github`, `git`, `workflow`) if the skill fits one;
  only add a new category directory once a skill actually needs it — don't
  pre-create empty ones for hypothetical future skills.
- Symlink it from both `claude/skills/<name>` and `codex/skills/<name>`
  (relative `../../skills/<category>/<name>` links, matching the existing
  ones — copy the pattern, don't invent a new one). The live symlink name is
  always the skill's basename, never the category.
- `install.sh`'s `for s in "$REPO"/skills/*/*/` loop already walks any
  category directory and links whatever it finds — no install.sh edit needed
  unless the tool wiring itself differs.
- Skip a skill if a marketplace plugin already installed for that tool covers
  the same trigger phrases — check the tool's available-skills/plugins list
  before adding a local copy that'll just shadow or duplicate it.

## Adding a new agent-tool directory (e.g. a third CLI)

- Mirror `claude/` and `codex/`: a top-level dir named after the tool, its
  own `README.md` documenting what's excluded and why, tool-specific config
  seeded (never linked) if the tool rewrites it at runtime, and any skills or
  hooks it shares with the others pulled from `skills/` / `hooks/` rather
  than copied in.
- Wire it into `install.sh`'s `install_links` the same way `~/.claude` and
  `~/.codex` are wired — extend the existing loop, don't fork a parallel one.
- Update the table in the root `README.md`.

See `claude/README.md` and `codex/README.md` for what's currently tracked and
excluded for each tool.
