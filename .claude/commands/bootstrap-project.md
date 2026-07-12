---
allowed-tools: Bash(git:*), Bash(ls:*), Bash(pwd:*), Bash(cat:*), Read, Write, Edit, Grep, Glob, Agent, AskUserQuestion
description: Audit or create the project's CLAUDE.md against the contract the generic agents rely on
---

## Context

- Arguments: $ARGUMENTS
- Working directory: !`pwd`
- Existing CLAUDE.md: !`test -f CLAUDE.md && echo "exists ($(wc -l < CLAUDE.md) lines)" || echo "missing"`
- Repo root files: !`ls -1 | head -30`

## Your task

The generic agent set is stack-agnostic on purpose — `CLAUDE.md` is where each project supplies its
stack, commands, and rules. This command makes sure the current project holds up its side of that
contract. The contract template lives at `.claude/templates/claude-md-template.md` — read it first;
its sections (What this is, Stack, Commands, Layout, Conventions, Boundaries, Verification) are the
checklist.

### Step 1 — Discover the project

Dispatch **scout** to establish the facts the file needs: languages and frameworks in use, how the
repo is laid out, how it is built/tested/linted/run (Makefile, package.json scripts, CI config are
the best sources), what is generated code, and any existing docs stating conventions. Verify
commands exist rather than inventing them — a `CLAUDE.md` with a wrong test command poisons every
future agent run.

### Step 2 — Audit or draft

**If `CLAUDE.md` exists:** compare it against the template's sections and the scout's findings.
Produce a gap report: missing sections, stale or wrong claims (verify suspicious commands by
running them read-only where safe), and content that belongs elsewhere (long prose, duplicated
README material). Propose concrete edits.

**If it is missing:** draft it from the template, filled with the discovered facts. Where discovery
could not answer something an agent will need — conventions that aren't visible in code,
boundaries, what "done" means here — ask the user, batched into one round of questions
(AskUserQuestion). Leave out sections that genuinely don't apply; never ship placeholder prose.

### Step 3 — Confirm and write

Show the user the proposed new file or the diff of proposed edits. Apply only after approval —
`CLAUDE.md` steers every future session in this repo, so the user signs it off.

### Quality bar

- Every command in the file has been seen in the repo (Makefile, scripts, CI) or confirmed by the user.
- Short and factual — each line should change how an agent behaves; cut anything derivable from
  one glance at the codebase.
- Boundaries section is explicit about what agents must never touch (generated files, migrations,
  secrets), because agents treat silence as permission.
