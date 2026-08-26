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
