---
allowed-tools: Bash(git:*), Bash(echo:*), Read, Grep, Glob, Agent, AskUserQuestion
description: Escalate a hard problem to the fable-consultant with a properly packaged briefing
---

## Context

- Arguments (the problem, optional): $ARGUMENTS
- Current branch: !`git branch --show-current 2>/dev/null || echo "(not a git repo)"`
- Git status: !`git status --short 2>/dev/null || echo "(not a git repo)"`

## Your task

Escalate to **fable-consultant** — the expensive, strongest-model second opinion. The value of the consultation is decided by the quality of the briefing, so most of this command is packaging. It also acts as a brake: if the gate below fails, say so and don't burn the escalation.

### Step 1 — Gate

Confirm this is a legitimate escalation. At least one must hold:

- **Stuck:** the problem survived at least two genuinely different serious attempts in this session (or documented prior sessions) — not just two retries of the same idea.
- **Arbitration:** two strong, concrete options are on the table and the choice is hard to reverse.
- **High-stakes gate:** a plan is about to execute something hard to reverse (data migration, auth change, payment logic) and deserves a final independent check.

If none holds, tell the user what cheaper step to take first (another debugging round, a code-reviewer pass, more evidence gathering) — and stop. The user can override explicitly.

Never route *security review of code* here — that is security-reviewer's job (and the strongest model's safety classifiers can false-positive on offensive security analysis). Arbitrating a security-relevant *design decision* is fine.

### Step 2 — Package the briefing

Assemble from the session (and by reading the repo where needed) a briefing with exactly these sections. If you cannot fill one, gather the missing information first — do not send a hollow briefing.

1. **Problem** — what is wrong or what must be decided, with the observable facts (error output, measurements, requirements) verbatim, not paraphrased.
2. **Attempts / options** — each approach already tried or on the table, what it showed or costs, and why it was insufficient. This tells the consultant which paths are dead.
3. **Constraints** — what a valid answer must respect: compatibility, deadlines, technology givens, things the user has already decided.
4. **Established facts worth re-checking** — the load-bearing assumptions the analysis rests on, listed explicitly so the consultant can attack them.
5. **The question** — one precise question. "What is the root cause of X?" or "Which of A/B do we execute, and why?" — never "any thoughts?".
6. **Pointers** — the specific files (`path:line`), logs, or documents the consultant should read first.

### Step 3 — Dispatch and relay

Dispatch **fable-consultant** with the briefing. When the verdict returns:

- Relay it to the user in full: verdict, reasoning, directions, confidence and tripwires.
- If the consultant overturned a premise the session had treated as fact, highlight that explicitly — it usually invalidates earlier conclusions.
- Propose the concrete next action in the pipeline (which agent executes which direction), but wait for the user before acting on a verdict that changes scope or touches anything hard to reverse.
