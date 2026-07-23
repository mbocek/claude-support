---
allowed-tools: Bash(git:*), Bash(pwd:*), Bash(echo:*), Read, Grep, Glob, Agent, AskUserQuestion
description: Fast-lane proof of concept — light scout → implementer (minimal, no tests/review) → approval → hand off to /feature
---

## Context

- Arguments (PoC request): $ARGUMENTS
- Current branch: !`git branch --show-current 2>/dev/null || echo "(not a git repo)"`
- Git status: !`git status --short 2>/dev/null || echo "(not a git repo)"`
- Working directory: !`pwd`

## Your task

Get a **minimal working version** of the request running as fast as possible, show it, and — once the user approves — hand it off to `/feature` for hardening. This is the fast lane: no plan-approval gate before code, no tests, no review inside this command. The discipline (tests, review, fix loop, docs) lives in `/feature`, which the user runs next.

If `$ARGUMENTS` is empty, ask the user what to prototype before doing anything else.

### Phase 0 — Brainstorm pickup (when applicable)

If `$ARGUMENTS` names a `brainstorm-*.md` file (or one in the working directory clearly matches the request), read it first — it is the decision record from `/brainstorm`. Take its **Core direction** as the thing to prototype; that is all `/poc` needs. Deliberately leave the artifact's **Open questions** and **Risks** unresolved — hardening them is the later `/feature` pass's job, not the PoC's. If the artifact is **map-mode** (`## Variants explored` instead of `## Core direction`), the "what" isn't decided yet: use AskUserQuestion to have the user pick one variant to prototype before proceeding, or send them back to `/brainstorm`.

### Phase 1 — Light recon (scout)

Dispatch **scout** with the request and one focused question: which parts of the codebase the PoC touches and which conventions to follow so the code fits the repo. Keep it light — no exhaustive mapping. Skip this phase entirely when the change is trivially localized and you already know the target files.

Do **not** dispatch the architect and do **not** open a plan-approval gate. The point of `/poc` is to skip straight to running code.

### Phase 2 — Minimal implementation (implementer)

Dispatch **implementer** with the request and the scout context. The PoC contract, stated explicitly to the implementer:

- Build the **smallest version that actually runs** and demonstrates the core idea.
- **No tests, no hardening, no review-driven polish.** Shortcuts, hardcoded values, and clearly-marked `TODO`s are acceptable where they buy speed.
- But it must genuinely work for the happy path — a PoC that doesn't run is not a PoC.
- Write directly into the working tree. If the working tree was already dirty at the start, point that out to the user first so they can decide whether to stash/commit — but do not create a branch or otherwise isolate the work.
- Report: what was built, files changed, how to run/verify it, and every deliberate shortcut taken.

### Phase 3 — Show & approve

Summarize for the user, drawing on the implementer's report:

- What now works and how to run/verify it.
- Files changed.
- The deliberate shortcuts and what a production version would still need.

Then let the user approve the PoC (or ask for a quick tweak — small adjustments stay in `/poc`; anything larger belongs in `/feature`). No review, security, or test agents run here.

### Phase 4 — Hand off to /feature

Once the user approves, **`/poc` is done.** Do not run reviewers, tests, or `/commit` yourself. Prepare the handoff and stop:

- Produce a concise handoff summary the user can carry into `/feature`: the original request, what the PoC implemented, the files it touched, and the shortcuts that still need to become real (tests, error handling, edge cases, security). If a brainstorm artifact was the input, name it in the summary so `/feature` reads it too — its open questions are still unresolved and belong in the hardening pass.
- Tell the user to run `/feature` next to finish the work — the PoC in the working tree is the starting implementation to harden, not something to rebuild from scratch.

### Rules

- Pass agent outputs forward — each agent receives what the previous one produced; they do not share your context.
- When work is genuinely independent, put all `Agent` calls in a single message so they run concurrently.
- Report failures verbatim — if the PoC doesn't run, say so; never present a broken prototype as working.
- Never quietly slide into full-feature mode: no tests, no review, no commit inside `/poc`. That is `/feature`'s job.
