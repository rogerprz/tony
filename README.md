# tony

Named after my ride-or-die Honda Element. It was there when I needed a ride, it helped me move, and carried me up and down the 5 highway multiple times. It was a reliable companion, and I hope this project can be too.

A shareable collection of reusable, day-to-day engineering skills in
the `SKILL.md` format — PR review, investigation, problem breakdown,
and more. Clone it, install it, and get more consistent AI-assisted
workflows across Claude Code, Claude.ai, and Codex CLI.

## What's a skill?

A skill is a folder containing a `SKILL.md` file: YAML frontmatter
(`name`, `description`) plus a Markdown instructions body. The
`description` field is what triggers auto-invocation — when your
request matches it, the assistant loads the full skill and follows
its process.

## Install

### Local install: Claude Code and Codex

With Git and Bash installed (macOS, Linux, or WSL), clone this repo
into a location you plan to keep and run:

```bash
git clone https://github.com/rogerprz/tony.git
cd tony
bash scripts/install-skills.sh --dry-run
bash scripts/install-skills.sh
```

Already cloned? Run the last two commands from this checkout. The
script links all skill folders containing `SKILL.md`, excluding the
contributor `TEMPLATE`, into:

| Tool | Personal skill directory | Invoke a skill |
| --- | --- | --- |
| Claude Code | `~/.claude/skills/` | `/pr-comments` |
| Codex app / CLI | `~/.agents/skills/` | `$pr-comments` or `/skills` |

These are the documented local discovery locations for
[Claude Code](https://code.claude.com/docs/en/skills) and
[Codex](https://learn.chatgpt.com/docs/build-skills).

To install for just one tool:

```bash
bash scripts/install-skills.sh --target claude
bash scripts/install-skills.sh --target codex
```

Rerunning is safe: existing links to this checkout are left alone,
and conflicting files, folders, or links stop the install before any
skills are added. Review and move conflicting entries aside yourself.
The script respects `CLAUDE_CONFIG_DIR`; set `TONY_CLAUDE_SKILLS_DIR`
or `TONY_CODEX_SKILLS_DIR` to override either destination, including
for a Codex installation configured to use `~/.codex/skills`.

Run `git pull` in this checkout to update linked skills, then rerun
the script to pick up newly added skills. Keep the checkout in place.
To uninstall a skill, remove only its symlink from the destination
folder. If a skill is renamed or removed upstream, remove its old
symlink too. Restart the app if newly installed skills don't appear.

### Claude Code plugin alternative

Use the marketplace instead if you prefer plugin-managed installation.
Choose this or the local Claude installation above to avoid duplicates.
Run these commands inside Claude Code:

```bash
/plugin marketplace add rogerprz/tony
/plugin install tony@tony
```

Then use `/tony:pr-comments` (or let it auto-trigger on "review the
PR comments"). For a quick local test without installing:

```bash
claude --plugin-dir ./plugins/tony
```

**Claude.ai:** Zip an individual skill folder under
`plugins/tony/skills/<skill-name>/` (the folder itself becomes the
zip root) and upload it via Customize → Skills. Requires "Code
execution and file creation" enabled in your account settings. There's
no marketplace/plugin mechanism on this platform — skills are uploaded
one at a time.

### ChatGPT

The script installs local skills for Codex; it does not install into
your ChatGPT account. ChatGPT supports standalone skills in its desktop
app and skills distributed through plugins across web, desktop, and
mobile. See the [official skills guide](https://learn.chatgpt.com/docs/build-skills)
for supported setup and invocation (`@` to select a skill). This repo's
existing marketplace manifest is for Claude Code; ChatGPT plugin
distribution requires separate packaging.

## Skills

- **`code-review`** — multi-axis review (correctness, readability,
  architecture, security, performance) with severity-labeled findings,
  change-sizing guidance, and a verdict.
- **`pr-comments`** — reviews the current PR's comments, checks each
  against the actual diff, flags due-diligence gaps, and produces a
  change plan. Doesn't auto-apply changes or reply to comments.
- **`is-review-ready`** — reviews your own branch, diff, or PR the way an
  outside reviewer would, before you request review, so the real
  reviewers don't spend a round on what you could have caught. Scope
  tiering, four review lenses, an evidence gate that keeps unproven
  findings from being reported as blockers, and a Findings list
  severity-labeled P0-P* and ordered by what actually holds up the
  merge. Run `tony:is-review-ready deep` for maximum recall: wider
  reading outside the diff, more specialists, and an independent pass
  that tries to disprove each finding. Reports only, never edits or
  comments.
- **`reviews-code`** — reviews a code change (diff, branch, or PR) for
  merge readiness and leaves P0-P* findings in the target doc's
  Changelog, then checks back on a timer so a companion agent (e.g.
  `tony:does-work`) can act on them and hand back, without a human
  polling either side.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the skill format and the
process for adding a new one.
