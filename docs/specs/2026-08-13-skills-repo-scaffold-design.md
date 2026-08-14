# franky: skills repo scaffold

## Purpose

`franky` is a shareable collection of reusable, day-to-day engineering
skills in the `SKILL.md` format (YAML frontmatter + Markdown
instructions). Goal: let engineers clone the repo and get better,
more consistent AI-assisted workflows for tasks like PR review,
investigation, and problem breakdown — usable in Claude Code,
Claude.ai (Customize → Skills upload), and Codex CLI (native
`SKILL.md` support). Plain ChatGPT only works via manual
upload/reference, no auto-triggering.

## Scope

This spec covers the initial scaffold and one worked example skill.
Additional skills are out of scope for this spec — each new skill is
added later via the process this repo documents in `CONTRIBUTING.md`.

## Repo structure

franky is a Claude Code **plugin**, distributed as a self-hosted
**marketplace** (one repo serves both roles), so skills are invoked
with the `franky:` namespace prefix (e.g. `franky:pr-comments`),
matching how plugins work today. Reference
implementation confirmed against the installed `superpowers` plugin
on this machine.

```
franky/
  .claude-plugin/
    marketplace.json
  plugins/
    franky/
      .claude-plugin/
        plugin.json
      skills/
        TEMPLATE/
          SKILL.md
        pr-comments/
          SKILL.md
  README.md
  CONTRIBUTING.md
```

No `LICENSE` file. The repo defaults to all-rights-reserved; this can
be revisited later if the user wants to formalize sharing terms.

### .claude-plugin/marketplace.json (repo root)

Makes the repo itself installable as a marketplace, self-referencing
its own single plugin:

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "franky",
  "description": "Reusable day-to-day engineering skills for Claude Code",
  "owner": { "name": "Roger Perez" },
  "plugins": [
    {
      "name": "franky",
      "description": "Reusable day-to-day engineering skills",
      "author": { "name": "Roger Perez" },
      "source": "./plugins/franky",
      "category": "productivity"
    }
  ]
}
```

### plugins/franky/.claude-plugin/plugin.json

Only `name` is strictly required; other fields included for parity
with `superpowers`' plugin.json shape:

```json
{
  "name": "franky",
  "description": "Reusable day-to-day engineering skills",
  "version": "0.1.0",
  "author": { "name": "Roger Perez" },
  "homepage": "https://github.com/rogerprz/franky",
  "repository": "https://github.com/rogerprz/franky"
}
```

The `franky:` namespace prefix comes from this file's `name` field,
not the folder name. Each skill folder's name becomes the suffix,
e.g. `skills/pr-comments/` → `franky:pr-comments`.

### Install / invocation

For anyone cloning or pointing Claude Code at the GitHub repo:

```
/plugin marketplace add rogerprz/franky
/plugin install franky@franky
```

Then `/franky:pr-comments` is available, same pattern as any other
installed marketplace plugin. Quick local dev/test without a
persistent install: `claude --plugin-dir ./plugins/franky`.

## Components

### README.md

Audience: an engineer discovering the repo for the first time.
Covers:

- One-paragraph explanation of what a skill is and why this repo
  exists ("share with others to be better engineers").
- Install instructions per platform:
  - Claude Code: `/plugin marketplace add rogerprz/franky` then
    `/plugin install franky@franky` (or `claude --plugin-dir
./plugins/franky` for a quick local test without installing).
  - Claude.ai: zip `plugins/franky/skills/<skill-name>/` (folder
    becomes zip root), upload via Customize → Skills. Requires "Code
    execution and file creation" enabled. No marketplace/plugin
    mechanism on this platform — each skill is uploaded individually.
  - Codex CLI: reads `SKILL.md` natively, same folder layout.
  - Plain ChatGPT: no auto-triggering; usable only as pasted or
    uploaded reference content in a Custom GPT / Project.
- Link to `CONTRIBUTING.md` for adding new skills.
- List of current skills (initially just `pr-comments`), one line
  each with its trigger description.

### CONTRIBUTING.md

Audience: someone adding a new skill to the repo. Covers:

- The `SKILL.md` format: required YAML frontmatter fields (`name`,
  `description`), Markdown instructions body.
- Why `description` matters most: it's the only thing loaded into
  context at discovery time across all installed skills, so it must
  be specific and imperative enough that the assistant reliably
  triggers on it — not a summary of what the skill contains.
- Naming convention: lowercase-kebab-case folder name under
  `plugins/franky/skills/` matching the skill's `name` field.
- Optional `references/` and `scripts/` subfolders for content loaded
  on demand (not loaded until the skill body directs the agent to
  read them) — keeps the main `SKILL.md` lean.
- Checklist for adding a skill:
  1. Copy `plugins/franky/skills/TEMPLATE/` to
     `plugins/franky/skills/<skill-name>/`.
  2. Fill in `name` and `description` (imperative, specific trigger
     conditions).
  3. Write the instructions body.
  4. Dry-run the skill against a real scenario and sanity-check the
     output.
  5. Add one line to the skill list in `README.md`.

### plugins/franky/skills/TEMPLATE/SKILL.md

A blank scaffold with placeholder frontmatter and a body outline
(purpose, process/checklist, expected output), so copying it is the
fastest path to a new skill.

### plugins/franky/skills/pr-comments/SKILL.md

**Trigger**: user references "PR comments" (or equivalent) for the
current pull request.

**Process the skill encodes**:

1. Fetch the current PR's review comments/threads (e.g. via `gh api`
   or `gh pr view --comments`, applied to the PR tied to the current
   branch).
2. For each comment, independently assess validity against the actual
   diff and surrounding code — don't take the reviewer's framing at
   face value.
3. For each comment, classify as one of:
   - Valid — needs a code change.
   - Valid, and reveals a due-diligence gap — flag what better
     investigation (e.g. checking callers, an edge case, a test path)
     would have caught this before the PR was pushed.
   - Not valid — explain the reasoning for pushing back.
4. Produce a plan: a list of concrete changes to make, grouped by
   comment, plus any comments to reply to instead of act on.
5. Do not auto-apply changes or reply to comments — the skill's
   output is the assessment and plan, which the user reviews and acts
   on themselves, consistent with the standing rule against
   committing/pushing without explicit ask.

**Testing**: since this is a prompt-driven skill, validation means
dry-running it against a real PR with existing comments and confirming
the plan output is sensible and correctly separates valid, valid + not
caught by due diligence, and invalid classifications — not a unit
test.

## Out of scope

- Any skill beyond `pr-comments` and the template.
- CI/tooling to lint `SKILL.md` files.
- License terms (deliberately omitted per user decision).
