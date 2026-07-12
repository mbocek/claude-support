---
allowed-tools: Bash(git:*), Bash(pwd:*), Bash(echo:*), Read, Grep, Glob, Agent, AskUserQuestion
description: End-to-end feature pipeline — scout → architect → approval → implementer → tests → review loop
---

## Context

- Arguments (feature request): $ARGUMENTS
- Current branch: !`git branch --show-current 2>/dev/null || echo "(not a git repo)"`
- Git status: !`git status --short 2>/dev/null || echo "(not a git repo)"`
- Working directory: !`pwd`

## Your task

Drive a feature from request to reviewed implementation using the agent pipeline. The pipeline encodes the discipline: no implementation without a plan, no completion without a clean review. You are the orchestrator — you dispatch agents, carry context between them, and involve the user only at the decision points marked below.

If `$ARGUMENTS` is empty, ask the user what to build before doing anything else.

### Phase 0 — Brainstorm handoff (when applicable)

If `$ARGUMENTS` names a `brainstorm-*.md` file (or one in the working directory clearly matches the request), read it first — it is the decision record from `/brainstorm`. Contract for using it:

- **Core direction and Assumptions are decided.** Pass them to the architect as givens; do not re-litigate them. If the architect finds a decided item untenable against the real code, that goes back to the user, not into silent redesign.
- **Open questions are genuinely open.** The architect must settle each one explicitly in the plan or surface it at the approval gate — never resolve one silently.
- Carry the artifact's risks into the plan's risk section so mitigations become steps, not prose.
- **Map-mode artifact** (has `## Variants explored` instead of `## Core direction`): the "what" is not decided yet, so do not start the pipeline. Summarize the variants and use AskUserQuestion to have the user pick one (or send them back to `/brainstorm` / `/consult` to converge). Only after a variant is chosen does it become the core direction and the pipeline proceeds.

### Phase 1 — Recon (scout)

Dispatch **scout** with the feature request and ask for: the parts of the codebase the feature touches, existing analogous implementations, relevant conventions, and gaps. Skip this phase only when the change is trivially localized and you already know the target files.

### Phase 2 — Plan (architect)

Dispatch **architect** with the feature request, the scout report, and — when present — the brainstorm artifact contract from Phase 0. Require the standard plan output (goal, design, ordered steps, risks, verification).

**Decision gate:** present the plan to the user — goal, design summary, steps, and especially risks/open questions. Use AskUserQuestion when the plan contains a genuine either-or the user must decide. Do not proceed to implementation until the user approves the plan or amends it. If the working tree is dirty, point that out here so the user can decide whether to commit/stash first.

### Phase 3 — Implement (implementer)

Dispatch **implementer** with the approved plan and scout context. For plans with independent steps touching disjoint files, you may dispatch parallel implementer runs — one per independent step; otherwise execute steps sequentially in one run. If the implementer reports a conflict between the plan and reality, take it back to the architect (or the user, if it changes scope) rather than letting the implementer improvise.

### Phase 4 — Test (test-engineer)

Dispatch **test-engineer** with the implementer's report: cover the new behavior, run the relevant suite. Skip only if the implementer already added the tests the plan required and ran them green.

### Phase 5 — Review loop (code-reviewer, security-reviewer)

1. Dispatch **code-reviewer** on the change (diff of the working tree / branch). If the change touches auth, secrets, payments, user input parsing, file handling, or external calls, dispatch **security-reviewer** in parallel.
2. If the review returns findings above nit level: send them to **implementer** to fix, then re-review the fixes. Repeat until the reviewer approves or only accepted nits remain. Cap the loop at 3 rounds — if it's still failing, stop and escalate to the user with the open findings.

### Phase 6 — Close out

- If the change made documentation stale (README, API docs, runbooks), dispatch **docs-writer**.
- Summarize for the user: what was built, files changed, verification and review results, and anything left open. Do **not** commit — suggest `/commit` instead.

### Rules

- Pass agent outputs forward — each agent must receive what the previous one produced; they do not share your context.
- Never skip the plan-approval gate, even for "small" features that grew out of the request.
- Report failures verbatim; never smooth over a red test or an unresolved finding.
