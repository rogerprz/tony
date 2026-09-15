---
name: does-work
description: "Use when asked to act on change requests left by a reviewing agent (often invoked with tony:reviews-work) in a spec or plan doc's Changelog. Sleeps in rounds of 5 checks, starting at 3-minute intervals and shrinking to 2, applying each new change request as it appears, until the changelog says it's done. Triggers: 'apply the review changes and wait for more', 'does:work', 'work through the changelog on this doc'."
---

# Does Work (tony:does-work)

## Purpose

Companion to `tony:reviews-work`. That skill leaves change requests inline in
a spec/plan doc's Changelog; this skill is the other side — it waits for
those requests, acts on them directly in the doc, and keeps waiting for more
until the reviewer says the doc is done. Run this one when the reviewer's
requests already exist (or are about to), so it sleeps first instead of
writing anything up front.

## Sleeping between checks — any agent, any harness

This skill is AI-agnostic: it does not depend on any one platform's tool
name. Use whatever built-in wait/sleep/scheduling mechanism your own harness
provides to pause between checks — for example Claude Code's `ScheduleWakeup`
tool, a generic sleep/delay tool, or a supported wait action. Pick whichever
one your environment actually exposes.

Whatever the mechanism, the rule is the same: **you sleep, you wake up, you
resume this skill yourself.** Never end the turn by describing the wait as
something "the reviewer's loop" or "the user" will pick back up — that's the
job of this skill's own loop. Only stop for a real stop condition (below),
and say so explicitly when you do.

## Changelog format

Same Changelog section, at the bottom of the doc under `## Changelog`, newest
entry on top. Use role `Worker` for every entry you write. When an entry
covers more than one distinct action, list them as a numbered sub-list under
the entry so the count and substance of each item is scannable at a glance —
never collapse several actions into one flat prose sentence:

```markdown
## Changelog

- **2026-09-09T14:40Z — Worker:**
  1. **Topic of change 1:** what you did or are about to do.
  2. **Topic of change 2:** what you did or are about to do.
```

A single-action entry can skip the sub-list and just state the one thing
after the colon. Entries from the other agent will say `Reviewer` (or
whatever role they used) — that's how you tell a genuinely new request apart
from your own last entry. When reading a `Reviewer` entry, its numbered
sub-list is the actual set of requested changes — treat each numbered item
as one discrete change to apply.

## Timing: rounds of 5, shrinking from 3 minutes to 2

The wait between checks is not fixed. It runs in **rounds**:

- Each round is up to **5 checks** at a fixed interval.
- The first round's interval is **3 minutes**.
- Every time a round ends because a *new reviewer entry arrived* (not
  because it ran out of checks), the next round's interval drops by
  **1 minute**, down to a floor of **2 minutes**. Later rounds stay at 2
  minutes once they hit the floor.
- A round that ends because all 5 checks passed with no new entry is a
  stop condition (see below) — the interval does not matter at that point.

The rationale: once changes start landing, later ones tend to be smaller
follow-ups, so shorter checks keep up without waiting as long between them.

## Stop conditions — the only two ways this loop ends

1. **The reviewer's changelog entry says the doc is done** — wording to the
   effect that it's ready, approved, or can move to the next phase. Stop and
   report to the user. If the doc is a spec (not already a plan), see
   **Next phase** below before ending your turn.
2. **A full round (5 checks) at the current interval passes with no new
   reviewer entry.** Stop — the reviewer appears to have gone quiet — and
   tell the user so.

## Next phase: spec marked ready → write the plan

If stop condition 1 fires and the doc you were working on is a **spec** (not
a plan already), don't just stop at "ready" — move the work into the next
phase:

- If the `superpowers:writing-plans` skill is available, invoke it to
  produce the implementation plan from the now-approved spec.
- If it isn't available, write the plan yourself directly, following
  standard planning best practices (clear phases, concrete file targets, a
  testing/verification strategy, no ambiguity left for the implementer).

This only applies when the doc is a spec. If you were working on a plan doc,
stop condition 1 is the end of this skill's work — there is no further phase
to hand off to.

Everything else (a new change request arriving, applying it, handing back)
keeps the loop going. Do not stop just because you finished applying a
change and handed back — that's exactly when you go back to sleep and keep
checking, per the timing rules above.

## Process

1. **Enter the check loop first — do not edit anything yet.** Sleep for the
   current round's interval (3 minutes on the very first check), then check
   the Changelog. Treat this as check 1 of round 1.
2. **On each wake, read the Changelog.**
   - **No entry from the reviewer since you last checked:** one check used.
     If this was check 5 of the current round with still nothing new, stop
     per stop condition 2 and tell the user. Otherwise sleep again for the
     same interval and repeat this step, incrementing the check count.
   - **A new entry from the reviewer (role isn't `Worker`):** go to step 3.
   - **The new entry says the doc is done:** stop per stop condition 1 and
     tell the user, without making further edits.
3. **Acknowledge, then act.**
   a. Add a new top-of-Changelog entry, role `Worker`, timestamped now,
      saying you've seen their request and are reviewing/making the
      change(s) — this tells the reviewer you're active if they check back
      before you finish.
   b. Read each numbered item in the reviewer's requested-change list and
      apply it directly to the doc (content, structure, whatever the
      request asked for — not just the Changelog). Work through every item,
      not just the first.
4. **Hand back, then keep going.** Add a Changelog entry, role `Worker`,
   with a numbered sub-list mirroring what you changed (one item per
   requested change you addressed), stating it's ready for another review
   pass. Start a new round: drop the interval by 1 minute (floor 2 minutes),
   reset the check count to 0, and go back to step 1. Do not stop here —
   the loop only ends via the stop conditions above.

## Output

Changelog entries plus the doc edits described in step 3b, written directly
into the target file, and a short chat message when the loop actually stops
(done, or the reviewer went quiet). This skill edits the target doc only —
no other files, no commits, no PRs.
