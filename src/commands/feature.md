---
allowed-tools: Bash(git:*), Bash(pwd:*), Bash(echo:*), Read, Grep, Glob, Agent, AskUserQuestion
description: End-to-end feature pipeline — scout → architect → approval → implementer → parallel tests + review → fix loop
---

## Context

- Arguments (feature request): $ARGUMENTS
- Current branch: !`git branch --show-current 2>/dev/null || echo "(not a git repo)"`
- Git status: !`git status --short 2>/dev/null || echo "(not a git repo)"`
- Working directory: !`pwd`

## Your task

Drive a feature from request to reviewed implementation using the agent pipeline. The pipeline encodes the discipline: no implementation without a plan, no completion without a clean review. You are the orchestrator — you dispatch agents, carry context between them, and involve the user only at the decision points marked below.

If `$ARGUMENTS` is empty, ask the user what to build before doing anything else.

### Phase 0 — Handoff pickup (when applicable)

**PoC handoff.** If the request indicates a proof of concept already exists — the user says they ran `/poc`, hands you a PoC summary, or the working tree holds uncommitted changes that clearly implement the request — treat the PoC as the **starting implementation, not something to rebuild.** In that case:

- Skip Phases 1–3 for the parts the PoC already covers. Do **not** re-scout, re-plan, or re-implement working code from scratch.
- Read the PoC summary (or inspect the working-tree diff) to understand what was built and which shortcuts it took — those shortcuts are the work: missing tests, error handling, edge cases, security.
- Establish the PoC diff as the review scope: run `git diff` (and `git status` for untracked files) to get the concrete file list the PoC touched, and pass that list to the reviewers and test-engineer — in a PoC handoff there is no implementer report to scope them from. Then enter at **Phase 4 (test & review)** over that diff and run the fix loop until it is production-quality. If the PoC left a genuine gap that needs new code (not just hardening), scope that gap through the architect/implementer first, but keep the working PoC as the base.
- Still honor the approval gate for any *new* design decisions the hardening surfaces — but the PoC's core direction is already accepted by virtue of the user running `/feature` on it.

**Brainstorm handoff.**

If `$ARGUMENTS` names a `brainstorm-*.md` file (or one in the working directory clearly matches the request), read it first — it is the decision record from `/brainstorm`. Contract for using it:

- **Core direction and Assumptions are decided.** Pass them to the architect as givens; do not re-litigate them. If the architect finds a decided item untenable against the real code, that goes back to the user, not into silent redesign.
- **Open questions are genuinely open.** The architect must settle each one explicitly in the plan or surface it at the approval gate — never resolve one silently.
- Carry the artifact's risks into the plan's risk section so mitigations become steps, not prose.
- **Map-mode artifact** (has `## Variants explored` instead of `## Core direction`): the "what" is not decided yet, so do not start the pipeline. Summarize the variants and use AskUserQuestion to have the user pick one (or send them back to `/brainstorm` / `/consult` to converge). Only after a variant is chosen does it become the core direction and the pipeline proceeds.

### Phase 0.5 — Size the change, then scale the pipeline to it

The full pipeline is calibrated for a real feature. Running all of it on a two-file change spends several strong-model agents to guard a diff a single reviewer could hold in its head. Before Phase 1, decide which track this request is on and **state the choice to the user in one line** ("small track: no architect, single reviewer") so they can override it.

**Small track** — all of these hold: the change is localized to files you can already name, it adds no new dependency, public contract, or schema change, and it touches none of the sensitive surfaces listed in Phase 4. Then:

- No scout fan-out. One focused scout, or none if the request already names the files.
- No architect dispatch. **You** write the plan — goal, the two or three steps, what could break — and it still goes through the Phase 2 approval gate. The gate protects the user's decision, not the architect's dispatch.
- Phase 4 runs `code-reviewer` alone; `test-engineer` only if the change alters behavior rather than text or config.
- Phase 6 dispatches `docs-writer` only if a document actually names what you changed.

**Full track** — everything else, and always when the request is a new feature or subsystem, spans multiple areas, changes a contract, or touches a sensitive surface. If sizing is genuinely unclear, take the full track; under-reviewing is the more expensive mistake.

Re-size once, upward only: if the small track uncovers real design work, stop and escalate to the full track from Phase 2 rather than improvising.

### Phase 1 — Recon (scout)

Dispatch **scout** with the feature request and ask for: the parts of the codebase the feature touches, existing analogous implementations, relevant conventions, and gaps. When the feature spans clearly separable areas (e.g. API + persistence + UI, or several services), fan out multiple scouts — one focused question each, all dispatched in a single message so they run concurrently — and merge their reports for the architect. Skip this phase only when the change is trivially localized and you already know the target files.

### Phase 2 — Plan (architect)

On the small track, skip the dispatch and write the plan yourself, then go straight to the decision gate below. Otherwise dispatch **architect** with the feature request, the scout report, and — when present — the brainstorm artifact contract from Phase 0. Require the standard plan output (goal, design, ordered steps, risks, verification).

**Decision gate:** present the plan to the user — goal, design summary, steps, and especially risks/open questions. Use AskUserQuestion when the plan contains a genuine either-or the user must decide. Do not proceed to implementation until the user approves the plan or amends it. If the working tree is dirty, point that out here so the user can decide whether to commit/stash first.

### Phase 3 — Implement (implementer)

Dispatch **implementer** with the approved plan and scout context. For plans with independent steps touching disjoint files, dispatch parallel implementer runs — one per independent step, all in a single message so they run concurrently; only execute sequentially when steps share files or depend on each other's output. If the implementer reports a conflict between the plan and reality, take it back to the architect (or the user, if it changes scope) rather than letting the implementer improvise.

### Phase 4 — Test & review, first round (test-engineer, code-reviewer, security-reviewer)

Once the implementation lands, dispatch the verification agents **in parallel, in a single message** — the set that the Phase 0.5 track calls for:

- **test-engineer** with the implementer's report and the plan's verification criteria: cover the new behavior, run the relevant suite. Skip only if the implementer already added the tests the plan required and ran them green.
- **code-reviewer** on the implementation change. Scope it to the implementer's reported files/diff and tell it regression tests are being authored concurrently — it should not flag missing coverage in this round; the re-review covers the tests.
- **security-reviewer**, if the change touches auth, secrets, payments, user input parsing, file handling, or external calls.

These are safe to run concurrently because the reviewers are read-only and the test-engineer only adds test files outside the reviewed diff.

### Phase 5 — Fix loop

If the reviews (or the test run) return findings above nit level: send them to **implementer** to fix, then re-dispatch the affected reviewers — in parallel if both had findings — on the fixes plus the new tests.

Scope the re-dispatch as a **delta review, not a fresh full review**: give the reviewer its own prior findings verbatim, the diff of the fixes, and the new test files, and ask it to (a) confirm each finding is actually resolved and (b) check the fix itself for new defects. It should not re-derive the whole change from scratch — that is what makes a three-round loop cost as much as three full reviews.

Repeat until the reviewers approve or only accepted nits remain. Cap the loop at 3 rounds — if it's still failing, stop and escalate to the user with the open findings.

### Phase 6 — Close out

- If the change made documentation stale (README, API docs, runbooks), dispatch **docs-writer**.
- Summarize for the user: what was built, files changed, verification and review results, and anything left open. Do **not** commit — suggest `/commit` instead.

### Rules

- Pass agent outputs forward — each agent must receive what the previous one produced; they do not share your context.
- Whenever you dispatch more than one subagent for independent work, dispatch them concurrently — all in a single message — so they run in parallel; never serialize dispatches that don't depend on each other.
- Never skip the plan-approval gate, even for "small" features that grew out of the request. The small track drops the architect *dispatch*, never the gate.
- Every dispatch costs real tokens. Dispatch an agent when its verdict can change what happens next; do not add one for reassurance.
- Report failures verbatim; never smooth over a red test or an unresolved finding.
