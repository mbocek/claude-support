---
allowed-tools: Bash(git:*), Bash(pwd:*), Read, Grep, Glob, Agent, AskUserQuestion
description: Structured debugging — reproduce → hypothesize → bisect → root cause → optional fix
---

## Context

- Arguments (bug description / symptom): $ARGUMENTS
- Current branch: !`git branch --show-current 2>/dev/null || echo "(not a git repo)"`
- Git status: !`git status --short 2>/dev/null || echo "(not a git repo)"`
- Recent commits: !`git log --oneline -10 2>/dev/null || echo "(not a git repo)"`

## Your task

Drive a disciplined debugging session using the **debugger** agent. The command exists to enforce order: reproduce before theorizing, diagnose before fixing.

If `$ARGUMENTS` is empty, ask the user for: the observed behavior, the expected behavior, when it started (if known), and how to trigger it (if known).

### Step 1 — Collect the evidence

Gather what exists before dispatching: error output, failing test names, logs, the suspected timeframe ("started after Friday's deploy" → candidate commit range from `git log`). Ask the user for artifacts they mentioned but didn't paste. Evidence collected here saves the expensive agent's tokens.

### Step 2 — Dispatch the debugger (diagnosis only)

Dispatch **debugger** with the symptom, evidence, and repo pointers. The contract:

- **Reproduce first** — a minimal reliable reproduction, ideally a failing test. If reproduction fails, return with what additional evidence is needed rather than theorizing.
- **Hypotheses → experiments → bisection** until the root cause is confirmed (full causal chain + reproduction disappears when the cause is removed).
- **No fix yet** — the deliverable of this step is the diagnosis and the ruled-out list.

### Step 3 — Present the diagnosis

Relay to the user: root cause, evidence chain, reproduction, and what was ruled out. **Stop here if the user only asked "why"** — the diagnosis is the deliverable; don't apply a fix until they ask for one.

### Step 4 — Fix (on approval)

When the user wants the fix, dispatch **debugger** (it holds the diagnosis context) to apply the minimal change that removes the cause plus the regression test that would have caught the bug, and to clean up all temporary instrumentation. Then dispatch **code-reviewer** on the fix — bug fixes written under pressure are prime regression material.

### Escalation

If two genuinely different diagnosis rounds fail to produce a confirmed root cause, suggest `/consult` — the failed attempts and collected evidence are exactly the briefing it needs.
