---
allowed-tools: Bash(ls:*), Bash(pwd:*), Bash(test:*), Bash(wc:*), Bash(echo:*), Bash(head:*), Read, Write, Edit, Grep, Glob, Agent, AskUserQuestion
argument-hint: [audit | path]
description: Audit or create the project's CLAUDE.md against the contract the generic agents rely on
---

## Context

- Arguments: $ARGUMENTS
- Working directory: !`pwd`
- Existing CLAUDE.md: !`test -f CLAUDE.md && echo "exists ($(wc -l < CLAUDE.md) lines)" || echo "missing"`
- Repo root files: !`ls -1 | head -30`

**Arguments** (optional): `audit` forces report-only mode — produce the gap report but make no edits even if the user would approve them; a path scopes the run to that subdirectory's `CLAUDE.md` instead of the repo root (useful in monorepos). Empty arguments mean: full run against the repo root.

## Your task

The generic agent set is stack-agnostic on purpose — `CLAUDE.md` is where each project supplies its
stack, commands, and rules. This command makes sure the current project holds up its side of that
contract. The contract template lives at `.claude/templates/claude-md-template.md` — read it first;
its sections (What this is, Stack, Commands, Layout, Conventions, Boundaries, Verification) are the
checklist.

### Step 1 — Discover the project

Dispatch **scout** to establish the facts the file needs — as parallel scouts in a single message,
one per independent question: (a) languages, frameworks, and repo layout; (b) build/test/lint/run
commands (Makefile, package.json scripts, CI config are the best sources); (c) conventions,
boundaries, generated code, and existing docs stating rules. For a small repo a single scout
covering all three is fine — but never run them one after another. Every command scout reports must
be traceable to a definition in the repo (Makefile target, script entry, CI step)
— a `CLAUDE.md` with an invented test command poisons every future agent run.

**If discovery comes back nearly empty** — no build system, no source code, or a project type scout
cannot read — do not fabricate anything. Report what was (not) found and ask the user for the
missing facts; a `CLAUDE.md` containing only the sections the user confirmed is a valid outcome.

### Step 2 — Audit or draft

**If `CLAUDE.md` exists:** compare it against the template's sections and the scout's findings.
Produce a gap report: missing sections, stale or wrong claims, and content that belongs elsewhere
(long prose, duplicated README material). For suspicious commands, dispatch one **scout** with the
full list to confirm each is still defined in the repo's build config — a single batched run, not
one dispatch per command; do not attempt to execute project build/test commands yourself; existence
in the config is the verification bar here. Propose concrete edits.

**If it is missing:** draft it from the template, filled with the discovered facts. Where discovery
could not answer something an agent will need — conventions that aren't visible in code,
boundaries, what "done" means here — ask the user, batched into one round of questions
(AskUserQuestion). Leave out sections that genuinely don't apply; never ship placeholder prose.

### Step 3 — Confirm and write

Show the user the proposed new file or the diff of proposed edits. Apply only after approval —
`CLAUDE.md` steers every future session in this repo, so the user signs it off. In `audit` mode,
stop after presenting the report and proposed edits; make no writes regardless of approval — the
user reruns without `audit` to apply.

### Quality bar

- Every command in the file has been seen in the repo (Makefile, scripts, CI) or confirmed by the user.
- Short and factual — each line should change how an agent behaves; cut anything derivable from
  one glance at the codebase.
- Boundaries section is explicit about what agents must never touch (generated files, migrations,
  secrets), because agents treat silence as permission.
