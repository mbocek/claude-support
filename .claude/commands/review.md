---
allowed-tools: Bash(git:*), Read, Grep, Glob, Agent
description: Review code changes using specialized agents
---

## Context

- Arguments: $ARGUMENTS
- Current branch: !`git branch --show-current`
- Default branch: !`git rev-parse --abbrev-ref origin/HEAD 2>/dev/null || echo "main"`
- Git status: !`git status --short`
- Commits ahead of default branch: !`git rev-list --count origin/HEAD..HEAD 2>/dev/null || echo "0"`

## Your task

Review code changes by dispatching specialized agents. Each agent reviews independently and produces its own report. **This is a read-only operation — no agent should modify any files.**

### Step 1: Parse arguments and determine scope

Parse `$ARGUMENTS` to determine **scope** and optional **path filter**.

| Input | Scope | Path filter |
|---|---|---|
| *(empty)* | auto-detect: `branch` if commits ahead > 0, else `changes` | none |
| `changes` | uncommitted changes (staged + unstaged) | none |
| `branch` | full branch diff against default branch | none |
| `<path>` (not `changes`/`branch`) | auto-detect | `<path>` |
| `changes <path>` | uncommitted changes | `<path>` |
| `branch <path>` | branch diff | `<path>` |

### Step 2: Gather diff and changed files

Run the appropriate git commands based on the resolved scope:

- **changes** scope: `git diff HEAD [-- <path>]`
- **branch** scope: `git diff <default-branch>...HEAD [-- <path>]`

Get the list of changed files: add `--name-only` to the same diff command.

Get the full diff content: the same diff command without `--name-only`.

**If there are no changes, report that and stop.**

### Step 3: Categorize changed files

Assign each file to one or more categories:

| Category | Matching patterns |
|---|---|
| **go-source** | `*.go` excluding `*_test.go` |
| **go-tests** | `*_test.go` |
| **frontend** | `*.svelte`, `*.ts`, `*.js`, `*.css`, `*.html` (excluding generated/bundled files) |
| **infrastructure** | `*.tf`, `*.tfvars`, `Dockerfile*`, `docker-compose*` |

Additionally, flag these **cross-cutting concerns** (checked against go-source and infrastructure changes):

- **architecture-review**: new Go packages/modules, new or changed domain types (aggregates, repositories, value objects), changed public interfaces, changes spanning 3+ packages, new service directories
- **ddd-review**: any changes to domain layer code, new bounded contexts, changed aggregate boundaries, repository interface changes
- **cloud-review**: changes to service-to-service communication, API contracts (proto, OpenAPI), resilience patterns, observability, data consistency mechanisms

### Step 4: Dispatch agents in parallel

For each category that has changes, construct a prompt and spawn the agent using the `Agent` tool. **Send ALL Agent calls in a single message so they run concurrently.**

Every agent prompt must:
1. State clearly this is a **code review** — read-only, no modifications
2. Include the full diff for the files relevant to that agent
3. List the changed files
4. Instruct the agent to read full current files when broader context is needed

#### Agent dispatch table

| Condition | `subagent_type` | Review focus |
|---|---|---|
| **go-source** has files | `go-code-reviewer` | Correctness, performance, concurrency safety, idiomatic Go, error handling. Also assess test coverage for the changed code. |
| **go-source** has files AND (**ddd-review** or **architecture-review** flagged) | `go-senior-developer` | DDD alignment, architectural decisions, domain modeling, package structure, design patterns. Do NOT duplicate what go-code-reviewer covers — focus on the higher-level design. |
| **go-tests** has files | `go-test-automation` | Test quality, table-driven patterns, testcontainers usage, assertion quality, missing edge cases. Suggest concrete additional test cases. |
| **frontend** has files | `svelte-senior-developer` | SvelteKit patterns, reactivity, SSR/CSR, load functions, component design, TypeScript usage. |
| **frontend** has UI component files | `ux-senior-developer` | Accessibility (WCAG 2.2 AA), interaction patterns, responsive design, UX best practices. |
| **infrastructure** has files | `aws-infra-architect` | Terraform quality, cost implications, security, resource sizing, best practices. |
| **cloud-review** flagged | `cloud-native-architect` | Service boundaries, resilience patterns, data consistency, API contract design, observability. |

**Only spawn agents for conditions that are met.** Never spawn an agent with an empty diff.

#### Prompt template for each agent

Use this structure when constructing each Agent prompt:

```
You are reviewing code changes. This is a READ-ONLY review — do not create, edit, or write any files.

## Review scope
- Scope: {changes|branch} review
- Branch: {current branch}
- Base: {default branch}

## Changed files (your area)
{list of files}

## Diff
```diff
{the diff content for these files only}
```

## Instructions
Read the full current version of the changed files for context. Then perform your review focusing on: {focus area from the table above}.

Structure your review with clear severity levels (Critical > Important > Minor).
```

### Step 5: Present results

After all agents complete, collect every issue they reported and assign each a short ID (e.g. `C1`, `C2` for Critical; `I1`, `I2` for Important; `M1`, `M2` for Minor). Then present results in **two parts**: a priority-grouped summary table, followed by the detail for each issue.

#### Part A — Summary table (grouped by priority)

Render one table per severity level in this order: **Critical → Important → Minor**. Skip a level entirely if it has no issues. Each row is one issue:

```
## Critical

| ID | Agent | File | Summary |
|---|---|---|---|
| C1 | {agent name} | {file:line} | {one-line description} |

## Important

| ID | Agent | File | Summary |
|---|---|---|---|
| I1 | {agent name} | {file:line} | {one-line description} |

## Minor

| ID | Agent | File | Summary |
|---|---|---|---|
| M1 | {agent name} | {file:line} | {one-line description} |
```

Keep the `Summary` column to a single short line so the table stays readable. Use `file:line` when the agent pointed to a specific location, otherwise just the file path or `—`.

#### Part B — Issue details

Below the tables, output full detail for every issue in the same order as the tables (Critical first, then Important, then Minor). Use the ID as the heading so rows in Part A link mentally to the detail in Part B:

```
---

## Details

### C1 — {one-line summary}
**Agent**: {agent name}
**File**: {file:line}

{full explanation from the agent — problem, why it matters, suggested fix. Do not truncate.}

### C2 — {one-line summary}
...
```

**Do not summarize, aggregate, or cross-reference between agents in the detail section** — each issue's detail is the agent's own words.

After the details, add a brief closing line listing which agents participated and the issue counts per severity (e.g. `go-code-reviewer: 1 Critical, 2 Important, 0 Minor`).

**If no agent reported any issues**, skip the tables and details and output a single line confirming the review found nothing.
