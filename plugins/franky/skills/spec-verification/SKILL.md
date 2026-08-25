---
name: spec-verification
description: "Use before presenting any design/spec/RFC section for approval, and again before writing the final spec file, when the document makes factual claims about existing code, schemas, or APIs (a method's behavior, a constraint's values, a construction site, a full field/call-site enumeration) or reuses an existing pattern from elsewhere in the codebase."
---

# Spec Verification

## Purpose

Design docs fail reviewers most often not because the design is wrong, but because a claim
inside it was never actually checked against the code it describes — it came from a
paraphrase, a memory of "how this usually works," or a research subagent's summary that was
accurate for orientation but too lossy for a load-bearing fact. This skill is a pre-flight
check that catches that class of error before a human reviewer has to.

## When to use

- Before presenting a design section for approval during brainstorming/spec-writing.
- Before writing the spec file to disk.
- Before re-presenting a spec after addressing review feedback (re-verify, don't just patch the
  specific line the reviewer quoted).

## Process

For every claim in the document that asserts something about **existing** code, schema, or
behavior — not the new thing being designed — apply these checks:

### 1. Primary-source check

If the sentence names a specific file, method, constraint, config value, or enumerates a
category ("every X does Y", "all N call sites"), open and read that source directly before
trusting the sentence — even if a research pass already summarized it. A summary is lossy on
purpose; it's good for orientation, not for a claim other design decisions get built on top of.

Concretely: grep or read the actual file. Don't write "X is constructed once at startup" or "the
constraint allows values A/B/C" from memory or a paraphrase — confirm the line number and the
literal values.

### 2. Pattern-reuse invariant check

When the design says "mirror how X already does Y" or reuses an existing mechanism, don't stop
at copying the shape. Answer explicitly: **why is that mechanism correct in its original
context, and does that same reason still hold here?**

A mechanism built for one invariant (e.g. "each row is independent, so a full-snapshot payload
is always safe") silently becomes wrong when applied somewhere that invariant doesn't hold (e.g.
a single multi-field row shared across many features, where a snapshot device with mostly-default
local values can clobber real remote data). If the invariant doesn't hold, the design needs to
diverge from the reused pattern, with the divergence stated explicitly — not silently copied.

### 3. Completeness-claim check

If the document claims a property holds across a whole category ("every field syncs", "all call
sites route through X"), the claim needs a literal, checkable list built from reading the actual
data — not a category description standing in for one ("everything else goes into the JSON
blob"). Enumerate it. A reviewer should be able to check the list against the source without
re-deriving it themselves.

### 4. Async/lifecycle race check

If the design introduces an async operation (a network fetch, a pull, anything awaited) that
later writes into a shared or mutable local reference (a store, a cached object, a singleton),
ask explicitly: **what happens if the context that triggered this changes before it resolves?**
(e.g. the signed-in account switches, the screen is dismissed, a newer request superseded this
one). Design the guard as part of the initial design, not as a reaction to a reviewer asking.

### 5. Self-consistency reread

Before presenting the document (a section, or the whole file), reread it once end-to-end
specifically looking for two sections that were each written independently and sound correct in
isolation but disagree with each other — e.g. one section says an action is blocked pending a
precondition, and a later section describes what happens when that precondition fails, without
the two agreeing on whether the block lifts. This class of bug doesn't need code access to catch,
only a deliberate full reread rather than checking each section only against itself as it's
written.

## Output

Apply the fixes inline in the document being written — this isn't a report-only skill. If a
claim fails the primary-source check, replace it with a verified one (cite the file/line). If a
reused pattern fails the invariant check, state the divergence explicitly in the doc rather than
silently copying the pattern. If a completeness claim isn't backed by an actual list, build the
list. If an async operation has no race guard, add one to the design before presenting it.

State plainly, when reporting back to the user, which of the five checks actually caught
something — don't claim a clean pass without having genuinely run all five.
