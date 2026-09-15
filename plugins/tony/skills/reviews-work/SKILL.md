---
name: reviews-work
description: "Use when asked to review a spec or plan doc and collaborate asynchronously with another agent (often invoked with tony:does-work) that is or will be editing the same doc. Leaves change requests in a Changelog section at the bottom of the file, then sleeps in rounds of 5 checks, starting at 3-minute intervals and shrinking to 2, re-reviewing whenever the other agent responds. Triggers: 'review this spec and wait for the other agent', 'reviews:work', 'collaborate on this plan doc'."
---

# Reviews Work (tony:reviews-work)

## Purpose

Review a spec or plan doc, leave change requests inline in the doc's own
Changelog instead of only in chat, then keep checking back on a timer so a
second agent (running `tony:does-work` on the same file) can pick up the
requests, act, and hand back without either side needing to be polled by a
human. The loop ends when the doc needs nothing further, or when the other
agent goes quiet.

## Sleeping between checks — any agent, any harness

This skill is AI-agnostic: it does not depend on any one platform's tool
name. Use whatever built-in wait/sleep/scheduling mechanism your own harness
provides to pause between checks — for example Claude Code's `ScheduleWakeup`
tool, a generic sleep/delay tool, or a supported wait action. Pick whichever
one your environment actually exposes.

Whatever the mechanism, the rule is the same: **you sleep, you wake up, you
resume this skill yourself.** Never end the turn by describing the wait as
something "the worker's loop" or "the user" will pick back up — that's the
job of this skill's own loop. Only stop for a real stop condition (below),
and say so explicitly when you do.

## Repository path and wakeup fallback

When the user supplies a document path, treat that path as authoritative and resolve it to an
absolute filesystem path before doing any work. Derive the repository/worktree from the target
document's parent directories; do not assume the current workspace or a same-named repository is
the target. Run all reads and writes against that resolved path, and report the resolved path in
the first progress update when it differs from the current working directory.

If `ScheduleWakeup` is unavailable in the current session, use a bounded Python timer as the
fallback rather than abandoning the check loop:

1. Create a temporary timer script outside the target repository (for example,
   `/private/tmp/tony_reviews_work_timer.py`) that sleeps for the requested number of seconds and
   prints a completion marker.
2. Run it for `delaySeconds` (normally 300 seconds) in a background/interactive command session.
3. Poll the session at intervals no longer than 30 seconds until the completion marker appears,
   then resume the review loop. Send a concise progress update while the timer is running.

The timer is only a wakeup substitute; it does not change the review semantics or authorize edits
outside the target document's Changelog.

## Changelog format

The Changelog lives at the bottom of the target doc, under a `## Changelog`
heading. Create the heading if it isn't there yet. **New entries always go
directly under the heading (top of the list), never appended at the bottom.**

Use role `Reviewer` for every entry you write. When you have more than one
change request, list them as a numbered sub-list under the entry so the
count and substance of each request is scannable at a glance — never
collapse several requests into one flat prose sentence:

```markdown
## Changelog

- **2026-09-09T14:32Z — Reviewer:**
  1. **Topic of change request 1:** the specific change needed.
  2. **Topic of change request 2:** the specific change needed.
```

A single-request entry can skip the sub-list and just state the one request
after the colon. Entries written by the other agent will say `Worker` (or
whatever role they used) — that's how you tell "my own last entry" apart
from "something new arrived".

## Timing: rounds of 5, shrinking from 3 minutes to 2

The wait between checks is not fixed. It runs in **rounds**:

- Each round is up to **5 checks** at a fixed interval.
- The first round's interval is **3 minutes**.
- Every time a round ends because a *new worker entry arrived* (not because
  it ran out of checks), the next round's interval drops by **1 minute**,
  down to a floor of **2 minutes**. Later rounds stay at 2 minutes once they
  hit the floor.
- A round that ends because all 5 checks passed with no new entry is a stop
  condition (see below) — the interval does not matter at that point.

The rationale: once the worker starts responding, later rounds tend to
involve smaller follow-up fixes, so shorter checks keep up without waiting
as long between them.

## Stop conditions — the only two ways this loop ends

1. **The doc needs nothing further** — either on the first read (skip the
   loop entirely) or after re-reviewing a worker's changes. Stop and report
   to the user that it's ready. If the doc is a spec (not already a plan),
   see **Next phase** below before ending your turn.
2. **A full round (5 checks) at the current interval passes with no new
   worker entry.** Stop — the worker appears to have gone quiet — and tell
   the user so.

## Next phase: spec marked ready → write the plan

If stop condition 1 fires and the doc you were reviewing is a **spec**
(not a plan already), don't just stop at "ready" — move the work into the
next phase:

- If the `superpowers:writing-plans` skill is available, invoke it to
  produce the implementation plan from the now-approved spec.
- If it isn't available, write the plan yourself directly, following
  standard planning best practices (clear phases, concrete file targets, a
  testing/verification strategy, no ambiguity left for the implementer).

This only applies when the reviewed doc is a spec. If you were reviewing a
plan doc, stop condition 1 is the end of this skill's work — there is no
further phase to hand off to.

Everything else (a new worker entry arriving, re-reviewing, writing more
change requests) keeps the loop going. Do not stop just because you wrote a
fresh batch of requests — that's exactly when you go back to sleep and keep
checking, per the timing rules above.

## Process

1. **Read the whole doc.** Review it on its merits (does it satisfy the
   stated goal, is anything ambiguous, missing, or inconsistent with prior
   decisions in the doc).
2. **Write change requests into the Changelog** as a numbered sub-list under
   one new entry, role `Reviewer`, ISO 8601 UTC timestamp, one number per
   requested change. If nothing needs to change, stop per stop condition 1
   immediately — do not enter the check loop for a doc that's already ready.
3. **Enter the check loop.** Sleep for the current round's interval (3
   minutes on the very first check), then check the Changelog. Treat this as
   check 1 of round 1.
4. **On each wake, re-read the Changelog.** Compare its top entry to the last
   one you wrote or saw.
   - **No new entry above yours:** one check used. If this was check 5 of
     the current round with still nothing new, stop per stop condition 2
     and tell the user. Otherwise sleep again for the same interval and
     repeat this step, incrementing the check count.
   - **A new entry from the other agent (role isn't `Reviewer`):** go to
     step 5.
5. **Acknowledge, then re-review.**
   a. Add a new top-of-Changelog entry, role `Reviewer`, timestamped now,
      saying you've seen their update and are re-reviewing — this tells the
      other agent you're active if they check back before you finish.
   b. Re-read the doc in full (not just the diff implied by their note) and
      judge whether it now satisfies what was asked.
   c. If more changes are needed: go back to step 2 (new numbered
      change-request entry), then start a new round at step 3 — drop the
      interval by 1 minute (floor 2 minutes) and reset the check count to 0.
   d. If nothing more is needed: stop per stop condition 1.

## Output

Changelog entries written directly into the spec/plan file at each step
above, plus a short chat message at the point the loop actually stops (ready,
or the other agent went quiet) summarizing what happened. This skill only
edits the target doc's Changelog section — it does not touch the rest of the
doc's content, code, or any other file.
