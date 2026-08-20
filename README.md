# franky

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
/plugin marketplace add rogerprz/franky
/plugin install franky@franky
```
Then use `/franky:pr-comments` (or let it auto-trigger on "review the
PR comments"). For a quick local test without installing:
```bash
claude --plugin-dir ./plugins/franky
```

**Claude.ai:** Zip an individual skill folder under
`plugins/franky/skills/<skill-name>/` (the folder itself becomes the
zip root) and upload it via Customize → Skills. Requires "Code
execution and file creation" enabled in your account settings. There's
no marketplace/plugin mechanism on this platform — skills are uploaded
one at a time.

**Codex CLI:** Reads `SKILL.md` natively — point it at
`plugins/franky/skills/<skill-name>/`.

**Plain ChatGPT:** No auto-triggering support. Usable only by pasting
or uploading a skill's `SKILL.md` as reference material in a Custom GPT
or Project.

## Skills

- **`code-review`** — multi-axis review (correctness, readability,
  architecture, security, performance) with severity-labeled findings,
  change-sizing guidance, and a verdict.
- **`pr-comments`** — reviews the current PR's comments, checks each
  against the actual diff, flags due-diligence gaps, and produces a
  change plan. Doesn't auto-apply changes or reply to comments.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the skill format and the
process for adding a new one.
