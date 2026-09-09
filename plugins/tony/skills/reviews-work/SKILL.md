---
name: reviews-work
description: "Use when asked to review a spec or plan doc and collaborate asynchronously with another agent (often invoked with tony:does-work) that is or will be editing the same doc. Leaves change requests in a Changelog section at the bottom of the file, then sleeps in 5-minute checks (up to 4) waiting for the other agent to respond, re-reviewing whenever it does. Triggers: 'review this spec and wait for the other agent', 'reviews:work', 'collaborate on this plan doc'."
---

# Reviews Work (tony:reviews-work)

## Purpose

Review a spec or plan doc, leave change requests inline in the doc's own
Changelog instead of only in chat, then keep checking back on a timer so a
second agent (running `tony:does-work` on the same file) can pick up the
requests, act, and hand back without either side needing to be polled by a
human. The loop ends when the doc needs nothing further, or when the other
agent goes quiet.

## Changelog format

The Changelog lives at the bottom of the target doc, under a `## Changelog`
heading. Create the heading if it isn't there yet. **New entries always go
directly under the heading (top of the list), never appended at the bottom.**

Each entry is one bullet:

```markdown
## Changelog

- **2026-09-09T14:32Z — Reviewer:** <the change request or note>
```

Use role `Reviewer` for every entry you write. Entries written by the other
agent will say `Worker` (or whatever role they used) — that's how you tell
"my own last entry" apart from "something new arrived".

## Process

1. **Read the whole doc.** Review it on its merits (does it satisfy the
   stated goal, is anything ambiguous, missing, or inconsistent with prior
   decisions in the doc).
2. **Write change requests into the Changelog**, one bullet per requested
   change, newest on top, role `Reviewer`, ISO 8601 UTC timestamp. If nothing
   needs to change, skip to step 6 immediately — do not enter the sleep loop
   for a doc that's already ready.
3. **Enter the check loop.** Call `ScheduleWakeup` with `delaySeconds: 300`
   and a `prompt` that names the file and the current check count, e.g.
   `tony:reviews-work resume <file path>, check 1/4`. Set `noop` based on
   whether anything changed this turn.
4. **On each wake, re-read the Changelog.** Compare its top entry to the last
   one you wrote or saw.
   - **No new entry above yours:** this was one check. If this was check 4
     with nothing new, stop — the other agent appears to have stopped —
     and tell the user so. Otherwise go back to step 3 with the count
     incremented.
   - **A new entry from the other agent (role isn't `Reviewer`):** go to
     step 5.
5. **Acknowledge, then re-review.**
   a. Add a new top-of-Changelog entry, role `Reviewer`, timestamped now,
      saying you've seen their update and are re-reviewing — this tells the
      other agent you're active if they check back before you finish.
   b. Re-read the doc in full (not just the diff implied by their note) and
      judge whether it now satisfies what was asked.
   c. If more changes are needed: go back to step 2 (new change-request
      entries, reset the check count to 0, resume the loop at step 3).
   d. If nothing more is needed: go to step 6.
6. **Mark it ready.** Add a final Changelog entry, role `Reviewer`, stating
   the doc is ready to move to the next step, and stop the loop (do not call
   `ScheduleWakeup` again).

## Output

Changelog entries written directly into the spec/plan file at each step
above, plus a short chat message at the point the loop stops (ready, or the
other agent went quiet) summarizing what happened. This skill only edits the
target doc's Changelog section — it does not touch the rest of the doc's
content, code, or any other file.
