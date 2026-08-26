# tony Skills Repo Scaffold Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Scaffold `tony` as a self-hosted Claude Code plugin marketplace, with a working `pr-comments` skill and a blank `TEMPLATE` skill, so it can be cloned and installed by others as `tony:pr-comments`.

**Architecture:** One repo plays both roles — marketplace (`.claude-plugin/marketplace.json` at repo root) and the single plugin it lists (`plugins/tony/`, with its own `.claude-plugin/plugin.json` and a `skills/` folder). No code to compile; every task's deliverable is a file (JSON or Markdown) that must be structurally valid and, where possible, verified by actually loading the plugin with `claude --plugin-dir`.

**Tech Stack:** Plain JSON (`plugin.json`, `marketplace.json`), Markdown with YAML frontmatter (`SKILL.md`), git. No build step, no package manager, no test framework — validation is JSON well-formedness plus loading the plugin in a real Claude Code session.

**Spec:** `docs/specs/2026-08-13-skills-repo-scaffold-design.md`

## Global Constraints

- Plugin/marketplace name is `tony` in both `marketplace.json` and `plugin.json` — this is what produces the `tony:` skill prefix.
- No `LICENSE` file — repo defaults to all-rights-reserved (deliberate, per spec).
- `skills/` lives at `plugins/tony/skills/`, not at repo root.
- Each `SKILL.md` requires YAML frontmatter with `description` (required) and `name` (recommended, must match the folder name).
- `pr-comments` skill must never auto-apply code changes or auto-reply to PR comments — output is a plan/assessment only, per the user's standing no-autonomous-action rule.
- Do not commit or push — leave changes staged/unstaged for the user to review, per standing rule (this plan's "Commit" steps stage-only or are skipped; see Task notes).

---

### Task 1: Marketplace and plugin manifests

**Files:**
- Create: `.claude-plugin/marketplace.json`
- Create: `plugins/tony/.claude-plugin/plugin.json`

**Interfaces:**
- Produces: the `tony` marketplace name (used by `/plugin marketplace add`) and the `tony` plugin name (used by `/plugin install tony@tony` and the `tony:` skill prefix consumed by every later task).

- [ ] **Step 1: Create the marketplace manifest**

`.claude-plugin/marketplace.json`:
```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "tony",
  "description": "Reusable day-to-day engineering skills for Claude Code",
  "owner": { "name": "Roger Perez" },
  "plugins": [
    {
      "name": "tony",
      "description": "Reusable day-to-day engineering skills",
      "author": { "name": "Roger Perez" },
      "source": "./plugins/tony",
      "category": "productivity"
    }
  ]
}
```

- [ ] **Step 2: Create the plugin manifest**

`plugins/tony/.claude-plugin/plugin.json`:
```json
{
  "name": "tony",
  "description": "Reusable day-to-day engineering skills",
  "version": "0.1.0",
  "author": { "name": "Roger Perez" },
  "homepage": "https://github.com/rogerprz/tony",
  "repository": "https://github.com/rogerprz/tony"
}
```

- [ ] **Step 3: Validate both files are well-formed JSON**

Run:
```bash
python3 -m json.tool .claude-plugin/marketplace.json > /dev/null && echo OK
python3 -m json.tool plugins/tony/.claude-plugin/plugin.json > /dev/null && echo OK
```
Expected: `OK` printed twice, no errors.

- [ ] **Step 4: Stage the files**

```bash
git add .claude-plugin/marketplace.json plugins/tony/.claude-plugin/plugin.json
```
Do not commit — leave staged for the user to review and commit themselves.

---

### Task 2: TEMPLATE skill scaffold

**Files:**
- Create: `plugins/tony/skills/TEMPLATE/SKILL.md`

**Interfaces:**
- Consumes: nothing (first skill file).
- Produces: the copy-paste starting point every future skill (including `pr-comments` in Task 3) is based on — the frontmatter shape (`name`, `description`) and section outline (Purpose, Process, Output) that `pr-comments` must match.

- [ ] **Step 1: Write the template**

`plugins/tony/skills/TEMPLATE/SKILL.md`:
```markdown
---
name: TEMPLATE
description: "Replace with an imperative, specific trigger condition, e.g. 'Use when the user asks to review the current PR's comments.' This is the ONLY field scanned for auto-triggering across all installed skills, so be concrete about when to fire, not what the skill contains."
---

# [Skill Name]

## Purpose

One or two sentences: what problem this skill solves and when a user
would reach for it.

## Process

Step-by-step instructions the agent follows. Be concrete and
imperative — this is a recipe, not a description.

1. ...
2. ...
3. ...

## Output

What the agent should produce or say when the process is complete —
e.g. a plan, a report, a set of file edits. State clearly whether the
skill takes any autonomous action or only produces output for the
user to review.
```

- [ ] **Step 2: Verify frontmatter parses**

Run:
```bash
python3 -c "
import re, sys
text = open('plugins/tony/skills/TEMPLATE/SKILL.md').read()
m = re.match(r'^---\n(.*?)\n---\n', text, re.DOTALL)
assert m, 'no frontmatter block found'
import yaml
data = yaml.safe_load(m.group(1))
assert 'description' in data, 'missing description field'
print('OK', data.get('name'), '-', data['description'][:40])
"
```
Expected: prints `OK TEMPLATE - Replace with an imperative...` with no
exception. If `yaml` isn't installed, run `pip3 install pyyaml` first.

- [ ] **Step 3: Stage the file**

```bash
git add plugins/tony/skills/TEMPLATE/SKILL.md
```

---

### Task 3: `pr-comments` skill

**Files:**
- Create: `plugins/tony/skills/pr-comments/SKILL.md`

**Interfaces:**
- Consumes: the frontmatter/section shape established by `plugins/tony/skills/TEMPLATE/SKILL.md` (Task 2).
- Produces: the `tony:pr-comments` skill, the one exercised end-to-end in Task 5's dry run.

- [ ] **Step 1: Write the skill**

`plugins/tony/skills/pr-comments/SKILL.md`:
```markdown
---
name: pr-comments
description: "Use when the user says 'PR comments', 'review the comments', or asks to check the current pull request's review feedback. Fetches the current PR's comments, independently assesses whether each is valid against the actual diff, flags any due-diligence gaps in the original work, and produces a change plan. Does not auto-apply changes or reply to comments."
---

# PR Comments Review

## Purpose

When a pull request has review comments, don't just treat every
comment as correct and start editing. This skill fetches the current
PR's comments, evaluates each one against the actual code, and asks a
second question beyond "is this valid": could better investigation
before pushing have caught this already? The output is a plan for the
user to review and act on, not code changes applied automatically.

## Process

1. Determine the current PR tied to the current branch. Run:
   ```bash
   gh pr view --json number,url,comments,reviews
   ```
   If this fails (no PR found, `gh` not authenticated), stop and tell
   the user what's missing instead of guessing which PR they mean.

2. Fetch the full comment/review thread detail, including inline
   diff comments:
   ```bash
   gh api repos/{owner}/{repo}/pulls/{number}/comments
   gh pr view {number} --comments
   ```
   Use whichever combination surfaces both top-level review comments
   and inline diff comments for this repo/PR.

3. Read the actual diff the comments refer to:
   ```bash
   gh pr diff {number}
   ```
   Do not assess a comment from its text alone — cross-reference the
   line(s) it points at in the real diff and surrounding file context
   (open the file if the diff snippet isn't enough to judge validity).

4. For each comment, classify it as exactly one of:
   - **Valid** — the code should change. State the specific edit
     needed (file, location, what changes).
   - **Valid, and reveals a due-diligence gap** — the code should
     change, AND flag what investigation before pushing would have
     caught this (e.g. "a test covering the empty-list case would
     have caught this", "checking the other three callers of this
     function would have surfaced the same issue there").
   - **Not valid** — explain the specific technical reason the
     comment doesn't hold, citing the actual code.

5. Produce a single output with two parts:
   - **Plan**: grouped by comment, the concrete change (or reply, for
     "not valid" comments) needed. This is a plan only — do not edit
     files or post replies to GitHub as part of this skill.
   - **Due-diligence summary**: a short list of any process gaps
     surfaced in step 4, so the user can see the pattern across the
     PR, not just comment-by-comment.

## Output

A plan-only report: comment-by-comment classification + concrete next
step, plus a due-diligence summary. Never auto-apply a code change,
never auto-reply to a GitHub comment, never commit or push as part of
running this skill — the user reviews the plan and acts on it
themselves.
```

- [ ] **Step 2: Verify frontmatter parses**

Run:
```bash
python3 -c "
import re
text = open('plugins/tony/skills/pr-comments/SKILL.md').read()
m = re.match(r'^---\n(.*?)\n---\n', text, re.DOTALL)
assert m, 'no frontmatter block found'
import yaml
data = yaml.safe_load(m.group(1))
assert data.get('name') == 'pr-comments'
assert 'description' in data
print('OK', data['name'])
"
```
Expected: prints `OK pr-comments`.

- [ ] **Step 3: Stage the file**

```bash
git add plugins/tony/skills/pr-comments/SKILL.md
```

---

### Task 4: README and CONTRIBUTING

**Files:**
- Create: `README.md` (overwrite the existing 8-byte placeholder)
- Create: `CONTRIBUTING.md`

**Interfaces:**
- Consumes: the install commands and file paths fixed in Task 1 (marketplace/plugin names) and Task 2/3 (skill folder location, frontmatter fields).
- Produces: nothing consumed by later tasks — this is the leaf/user-facing documentation layer.

- [ ] **Step 1: Write README.md**

```markdown
# tony

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

**Claude Code:**
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

**Codex CLI:** Reads `SKILL.md` natively — point it at
`plugins/tony/skills/<skill-name>/`.

**Plain ChatGPT:** No auto-triggering support. Usable only by pasting
or uploading a skill's `SKILL.md` as reference material in a Custom GPT
or Project.

## Skills

- **`pr-comments`** — reviews the current PR's comments, checks each
  against the actual diff, flags due-diligence gaps, and produces a
  change plan. Doesn't auto-apply changes or reply to comments.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the skill format and the
process for adding a new one.
```

- [ ] **Step 2: Write CONTRIBUTING.md**

```markdown
# Contributing to tony

## Skill format

Every skill is a folder under `plugins/tony/skills/` containing a
`SKILL.md`:

```markdown
---
name: your-skill-name
description: "Imperative, specific trigger condition — when should
  this skill fire, not what it contains."
---

Markdown instructions body: purpose, process, output.
```

- `description` is the only field scanned for auto-triggering across
  every installed skill, before the full body ever loads into
  context. A vague description means the skill never fires. Write it
  as a trigger condition ("Use when the user asks to...", "Use when
  reviewing...") rather than a summary.
- `name` should match the folder name, lowercase-kebab-case.
- Optional `references/` and `scripts/` subfolders hold content that's
  only loaded when the skill body explicitly directs the agent to
  read it — keeps the main `SKILL.md` lean. Only add these if the
  skill actually needs them.

## Adding a new skill

1. Copy `plugins/tony/skills/TEMPLATE/` to
   `plugins/tony/skills/<skill-name>/`.
2. Fill in `name` and `description` in the frontmatter.
3. Write the instructions body: Purpose, Process, Output.
4. Dry-run the skill against a real scenario in your own session and
   sanity-check the output. Skills are prompt-driven — there's no unit
   test, so this manual dry run is the validation step.
5. Add one line to the skill list in `README.md`.
6. Open a PR.
```

- [ ] **Step 3: Stage the files**

```bash
git add README.md CONTRIBUTING.md
```

---

### Task 5: End-to-end load verification

**Files:**
- None created — this task only verifies Tasks 1-4 together.

**Interfaces:**
- Consumes: the full repo tree produced by Tasks 1-4.
- Produces: confirmation that `tony:pr-comments` actually resolves as a real, loadable skill — the plan's overall acceptance test.

- [ ] **Step 1: Confirm the full tree matches the spec**

Run:
```bash
find . -path ./.git -prune -o -type f -print | sort
```
Expected to include (at minimum):
```
./.claude-plugin/marketplace.json
./plugins/tony/.claude-plugin/plugin.json
./plugins/tony/skills/TEMPLATE/SKILL.md
./plugins/tony/skills/pr-comments/SKILL.md
./README.md
./CONTRIBUTING.md
```
No `./LICENSE` file present.

- [ ] **Step 2: Load the plugin locally and confirm the skill is listed**

Run, from the repo root:
```bash
claude --plugin-dir ./plugins/tony
```
Inside the session, list available skills (or check the system
skill listing shown at session start) and confirm `tony:pr-comments`
and `tony:TEMPLATE` both appear with their descriptions intact.
Exit the session after confirming.

- [ ] **Step 3: Sanity-check the pr-comments skill against a real PR (optional, requires an open PR with comments)**

If a PR with review comments is available in this or another repo,
invoke the skill (e.g. say "review the PR comments") and confirm the
output is a plan (not an auto-applied change), correctly separates
valid / valid-with-due-diligence-gap / not-valid comments, and never
attempts to commit, push, or reply on its own.

- [ ] **Step 4: Report status to the user**

Summarize what was created and staged (nothing committed), and that
Task 5's manual verification passed, so the user can review the
staged diff and decide whether to commit.
