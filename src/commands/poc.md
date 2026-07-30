---
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, AskUserQuestion
argument-hint: [what to prototype | brainstorm-*.md]
description: Fast lane to a minimal working prototype — built inline, no subagents, no tests; hands off to /feature
---

## Context

- Arguments (PoC request): $ARGUMENTS
- Current branch: !`git branch --show-current 2>/dev/null || echo "(not a git repo)"`
- Git status: !`git status --short 2>/dev/null || echo "(not a git repo)"`
- Working directory: !`pwd`

## Your task

Build a **minimal working version** of the request yourself, in this session, then stop. You do the recon and you write the code — **no subagents**. No tests, no review, no commit: that discipline lives in `/feature`, which the user runs next.

If `$ARGUMENTS` is empty, ask what to prototype before doing anything else.

### Input

If `$ARGUMENTS` names a `brainstorm-*.md` file (or one in the working directory clearly matches the request), read it first — it is the decision record from `/brainstorm`. Take its **Core direction** as the thing to prototype; that is all `/poc` needs. Leave its **Open questions** and **Risks** deliberately unresolved — hardening them is the later `/feature` pass's job. If the artifact is map-mode (`## Variants explored` instead of `## Core direction`), the "what" is not decided yet: have the user pick one variant before you write code.

### Build

Orient only as far as you need — the files the change touches and the conventions to follow. Then implement, directly in the working tree on the current branch: no branch, no worktree, no isolation.

The contract:

- The **smallest version that actually runs** and demonstrates the core idea.
- The best quality reachable *without slowing down* — idiomatic for this repo, but shortcuts, hardcoded values, and clearly-marked `TODO`s are fine wherever they buy speed.
- It must genuinely work on the happy path, and you verify that yourself: run it, or the narrowest command that proves it. A PoC that does not run is not a PoC.
- No tests, no hardening, no polish pass. Error handling only where the happy path needs it.
- If the working tree was already dirty when you started, say so in one line before writing anything — the user may want to stash first, and `/feature` later reads this diff as its scope.

### When you hit something fundamental

A missing dependency, an assumption the code contradicts, two viable directions: **decide and keep going.** Take the option that keeps the PoC smallest, remember the decision for the summary, and do not stop to ask. Interrupt the user mid-run only when you genuinely cannot proceed.

### Report

Work quietly — no phase announcements, no running commentary. When the PoC runs, give one short summary:

- What works, and the command that shows it.
- Files touched.
- Shortcuts taken and calls you made on your own — this is the list `/feature` will harden.

Then stop, and tell the user to run `/feature` next: the PoC in the working tree is the starting implementation to harden, not something to rebuild.

### Rules

- Never dispatch a subagent from `/poc` — the whole point is one fast inline pass.
- Report failures verbatim — if the PoC does not run, say so; never present a broken prototype as working.
- Never slide into full-feature mode: no tests, no review, no commit here. That is `/feature`'s job.
