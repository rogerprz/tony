---
name: does-work
description: "Use when asked to act on change requests left by a reviewing agent (often invoked with tony:reviews-work) in a spec or plan doc's Changelog. Sleeps in 5-minute checks (up to 4) waiting for a change request to appear, then applies it and hands back. Triggers: 'apply the review changes and wait for more', 'does:work', 'work through the changelog on this doc'."
---

# Does Work (tony:does-work)

## Purpose

Companion to `tony:reviews-work`. That skill leaves change requests inline in
a spec/plan doc's Changelog; this skill is the other side — it waits for
those requests, acts on them directly in the doc, and hands back for another
look. Run this one when the reviewer's requests already exist (or are about
to), so it sleeps first instead of writing anything up front.

## Changelog format

Same Changelog section, at the bottom of the doc under `## Changelog`, newest
entry on top. Use role `Worker` for every entry you write:

```markdown
## Changelog

- **2026-09-09T14:40Z — Worker:** <what you did, or what you're about to do>
```

Entries from the other agent will say `Reviewer` (or whatever role they
used) — that's how you tell a genuinely new request apart from your own last
entry.

## Process

1. **Enter the check loop first — do not edit anything yet.** Call
   `ScheduleWakeup` with `delaySeconds: 300` and a `prompt` naming the file
   and check count, e.g. `tony:does-work resume <file path>, check 1/4`. Set
   `noop: true` for this first call since nothing has happened yet.
2. **On each wake, read the Changelog.**
   - **No entry from the reviewer since you last checked:** one check used.
     If this was check 4 with still nothing new, stop — the reviewer hasn't
     responded — and tell the user so. Otherwise repeat step 1 with the
     count incremented, `noop: true`.
   - **A new entry from the reviewer (role isn't `Worker`):** go to step 3.
3. **Acknowledge, then act.**
   a. Add a new top-of-Changelog entry, role `Worker`, timestamped now,
      saying you've seen their request and are reviewing/making the
      change — this tells the reviewer you're active if they check back
      before you finish.
   b. Read the requested change(s) and apply them directly to the doc
      (content, structure, whatever the request asked for — not just the
      Changelog).
4. **Hand back.** Add a final Changelog entry, role `Worker`, summarizing
   what you changed and stating it's ready for another review pass. Stop —
   do not restart the sleep loop yourself; the reviewer's own loop (or the
   user) picks it back up.

## Output

Changelog entries plus the doc edits described in step 3b, written directly
into the target file, and a short chat message when the loop stops (handed
back for review, or the reviewer went quiet). This skill edits the target
doc only — no other files, no commits, no PRs.
