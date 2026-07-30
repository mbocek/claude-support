---
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Agent, AskUserQuestion
argument-hint: [feature request | brainstorm-*.md | (after /poc)]
description: End-to-end feature work done inline — plan → implement → tests and e2e → review subagents only where they earn it → fix loop
---

## Context

- Arguments (feature request): $ARGUMENTS
- Current branch: !`git branch --show-current 2>/dev/null || echo "(not a git repo)"`
- Git status: !`git status --short 2>/dev/null || echo "(not a git repo)"`
- Working directory: !`pwd`

## Your task

Take the request to a finished, verified change **yourself, in this session**. You plan, you implement, you run the tests. The only subagents you may dispatch are `code-reviewer` and `security-reviewer`, and only when the triggers in step 5 fire — everything else is your own work.

If `$ARGUMENTS` is empty, ask what to build before doing anything else.

### Working style

- **Solve it yourself.** Interrupt the user only for an answer that is genuinely not yours to give — a scope or product decision, or a fact you cannot get from the code or the repo.
- **Work around, then report.** When something blocks you mid-run and a reasonable workaround exists, take it, keep going, and put it in the closing summary instead of stopping.
- **Quiet while working.** No phase announcements, no running commentary.
- **Report failures verbatim.** Never narrate around a red test or an unresolved finding.

### 1. Input

The request arrives in one of three shapes:

- **PoC handoff** — the user ran `/poc`, hands you its summary, or the working tree holds uncommitted changes that clearly implement the request. The PoC is the **starting implementation, not something to rebuild**: do not re-plan or rewrite working code. The `/poc` summary is the authority on what was built — its shortcuts and the calls it made on its own *are* this run's work list; derive that list from the diff yourself only when no summary is at hand. `git diff` plus `git status` for untracked files gives the scope. Its core direction is already accepted by virtue of the user running `/feature` on it, so skip step 2's planning for what already works — but the work list itself goes through step 3: every shortcut on it gets turned into real code (error handling, edge cases, the hardcoded value made real) before anything is verified. Plan properly only the genuine gaps that need new design, not just hardening.
- **Brainstorm artifact** — `$ARGUMENTS` names a `brainstorm-*.md` file, or one in the working directory clearly matches the request. Read it: **Core direction and Assumptions are decided**, so treat them as givens and do not re-litigate them; if the real code makes a decided item untenable, that goes back to the user, never into silent redesign. **Open questions are genuinely open** — settle each one explicitly in the plan or put it to the user at the gate; never resolve one silently. Carry its risks into the plan as steps, not prose. If the artifact is map-mode (`## Variants explored` instead of `## Core direction`), the "what" is not decided: have the user pick a variant before you plan anything.
- **Plain request** — start from the code.

### 2. Plan

Orient yourself first: the files the change touches, the conventions in `{{GUIDE}}`, and any analogous implementation already in the repo. Then write the plan — goal, ordered steps, what could break, and how you will verify it. Keep it yours; it does not need to be shown unless the gate below fires.

**Approval gate — conditional.** Stop and present the plan only when it contains a decision that is genuinely the user's:

- a trade-off the code cannot settle,
- a change to a public contract, schema, or user-visible behavior,
- a new dependency,
- something hard to reverse (data migration, deletion, external side effect),
- an open question carried in from a brainstorm artifact.

Use AskUserQuestion when it is a real either-or. If the plan holds no such decision, do not open a gate — build it. If the working tree was already dirty when you started, say so here in one line.

### 3. Implement

Write the code yourself, following the surrounding conventions. Keep the plan honest: when reality contradicts it, re-plan — and re-check whether the change now trips the gate — rather than improvising past it.

### 4. Verify — the whole loop

This is what separates `/feature` from `/poc`, so none of it is optional:

- Cover the new behavior with tests, at the level and in the framework the project already tests at.
- Run the unit/integration suite, then the e2e suite where the project has one. Commands come from `{{GUIDE}}`; discover them if the guide is silent, and say so plainly if the project has none.
- **Green means observed green.** A suite you did not run is not a passing suite. Report red output verbatim and fix it — never report verification you did not actually perform.

### 5. Review

Dispatch **`security-reviewer`** — mandatory, not a judgment call — whenever the change touches authentication or authorization, secrets or credentials, payments, parsing of user-controlled input, file or path handling, deserialization, or outbound calls to external systems. Self-reviewing your own code for security is the weakest check there is.

Dispatch **`code-reviewer`** when the diff is large, spans several modules, changes a public contract or a schema, or involves concurrency, migrations, or caching.

When both trigger, dispatch them in a single message so they run in parallel. They do not share your context — give each the concrete file list or diff, the plan, and the tests you wrote.

When neither trigger fires, do your own review pass over the full diff instead: read it as a whole against the plan, hunting for what you got wrong rather than confirming that it looks fine.

### 6. Fix loop

Fix findings above nit level yourself. Then re-dispatch only the reviewer that raised them, as a **delta review, not a fresh one**: give it its own findings verbatim, the diff of the fixes, and the new tests, and ask it to confirm each finding is resolved and to check the fixes for new defects. It should not re-derive the whole change — that is what makes a three-round loop cost as much as three full reviews.

Cap the loop at 3 rounds. If findings survive that, stop and carry them into the summary as open.

### 7. Close out

Update documentation the change made stale — README, API docs, runbooks — yourself.

Then give **one summary: short by default, detailed only where detail carries weight.**

- What was built, and what verification actually ran — suite, e2e, reviewers — with the real result.
- Files changed.
- **Open / deferred** — everything you worked around, every call you made alone, anything you could not resolve, and any surviving review findings. This is the section that earns its detail.

Do not commit — suggest `/commit`.

### Rules

- The only subagents `/feature` dispatches are `code-reviewer` and `security-reviewer`, per the triggers in step 5. Everything else is your own work.
- The security trigger is a hard rule, not a preference — when the change touches a listed surface, the reviewer runs.
- Do not interrupt for what you can decide; do not decide what is the user's to decide.
- Never present unverified work as finished.
