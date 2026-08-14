# Contributing to franky

## Skill format

Every skill is a folder under `plugins/franky/skills/` containing a
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

1. Copy `plugins/franky/skills/TEMPLATE/` to
   `plugins/franky/skills/<skill-name>/`.
2. Fill in `name` and `description` in the frontmatter.
3. Write the instructions body: Purpose, Process, Output.
4. Dry-run the skill against a real scenario in your own session and
   sanity-check the output. Skills are prompt-driven — there's no unit
   test, so this manual dry run is the validation step.
5. Add one line to the skill list in `README.md`.
6. Open a PR.
