---
name: loop-pr-comments
description: "Use when the user says 'loop PR comments', '/loop-pr-comments', or asks to keep checking the current PR for new review comments. Runs tony:pr-comments, then sleeps and re-checks up to 3 times (15, 10, then 5 minutes by default). Any round that finds comments to fix restarts the loop."
---

# Loop PR Comments (tony:loop-pr-comments)

## Purpose

Run `tony:pr-comments` on the current PR, then keep watching for new
review comments. Invoking this skill is the explicit request to commit
and push for every `tony:pr-comments` round in this loop. It does not
carry over to other work in the session.

## Arguments

- Optional start interval in minutes (for example `/loop-pr-comments 20`).
  Default: 15.
- Each later check is 5 minutes shorter than the one before.
- Floor: 5 minutes. Never sleep less than 5 minutes.

## Process

1. **First round:** invoke `tony:pr-comments` via the Skill tool and
   follow it exactly.

2. **Set up the countdown:** `check = 1`, `interval = start` (default 15).

3. **Sleep** for `interval` minutes. Use your harness's wait mechanism
   (Claude Code: `ScheduleWakeup`; fallback: the bounded Python timer
   described in `tony:does-work`). You resume the loop yourself when you
   wake. Never end the turn as if someone else will pick it up.

4. **Check:** invoke `tony:pr-comments` again.

5. **Decide:**
   - **Found comments or fixes** (any valid comment fixed, any pushback
     posted, or `tony:fix-issues` changed anything): restart the loop.
     Go to step 2.
   - **Nothing to do:** `check = check + 1`,
     `interval = max(interval - 5, 5)`. If `check <= 3`, go to step 3.
     Otherwise stop.

6. **Stop early** when the PR is merged or closed, or when
   `tony:pr-comments` fails twice in a row. Say why.

## Default schedule

With no new comments: sleep 15, check, sleep 10, check, sleep 5, check,
stop. A round with fixes resets back to 15.

## Output

After each round, one short update: round number, what was found, next
sleep time. When the loop ends, report:

1. **Rounds run:** count and total time.

2. **Comments handled:** the combined `tony:pr-comments` reports.

3. **Why it stopped:** 3 quiet checks, PR merged or closed, or errors.
