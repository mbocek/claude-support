---
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Agent, AskUserQuestion
argument-hint: [what to build | brainstorm-*.md]
description: Design a change with the user on the strong session model and write a spec a cheaper model can execute — feeds /build
---

## Context

- Arguments: $ARGUMENTS
- Today: !`date +%Y-%m-%d`
- Current branch: !`git branch --show-current 2>/dev/null || echo "(not a git repo)"`
- Git status: !`git status --short 2>/dev/null || echo "(not a git repo)"`

## Your task

Agree the design with the user, then write it down as a spec that `implementer` — a cheaper model that executes literally and never designs — can carry out without making a single decision. Everything that needs judgment happens here; `/build` only executes and verifies.

If `$ARGUMENTS` is empty, ask what to build. If it names a `brainstorm-*.md`, its Core direction and Assumptions are decided; its Open questions get settled here.

Write in the user's language; the spec's headings stay as in the template below.

### 1. Understand

Read the code the change touches and the closest analogous implementation in the repo; dispatch `scout` when that means sweeping many files. Then discuss the approach with the user: short exchanges, your recommendation with its trade-offs, their call on anything that is theirs to decide (scope, public contracts, new dependencies, hard-to-reverse steps). Stop discussing once nothing material is open.

### 2. Write the acceptance tests

Where the project has a test framework, write the tests that define "done" yourself, in the project's style — they are the quality bar the cheaper model cannot lower. Run them once: they must fail, and only because the feature is missing — a typo or a broken fixture would send the implementer chasing the wrong thing. List them as frozen in the spec.

### 3. Write the spec

Path: `spec-<short-slug>-<YYYY-MM-DD>.md` in the working directory. Every step must be executable without judgment: name exact files and signatures, point at a pattern to copy (`path:line`), and say what "done" means as a runnable command. If a step cannot be specified that tightly, the design is not finished — go back to step 1.

A step that changes what a user sees specifies the layout, not just the contents: which controls share a row, how wide each is, how sections are spaced, and an existing screen it must look like (route or `path:line`). "Add a field for X" leaves the placement to wherever the markup happens to fall, and type checks, tests and a code review all pass on a screen nobody would ship. Give each such screen a visual acceptance criterion the build checks on a screenshot.

```markdown
# {Title}

## Goal
{1–3 sentences: what changes for whom.}

## Decisions
- {Each design decision made with the user, one line each — the implementer must not revisit these.}

## Steps
1. **{Step}** — files: `{path}`; interface: `{signature / type}`; follow: `{path:line}`; notes: {only what the pattern does not already show}

## Frozen files
- `{acceptance test or fixture path}` — must not be modified

## Acceptance criteria
- `{command}` passes
- {any other checkable criterion, phrased so it is pass/fail}
- {per changed screen: `{route}` — what the screenshot must show, e.g. "X and Y on one row, styled like {reference screen}"}

## Out of scope
- {What must not be touched or added.}

## Stop and report if
- {Conditions where the implementer must stop instead of improvising — e.g. "the X interface already exists with a different shape".}

## Review focus
- {What the reviewer should check hardest: the risky part of this change.}
- Sensitive surfaces: {auth / secrets / payments / user input / files / deserialization / outbound calls — or "none"}
```

### 4. Independent review of the spec

Dispatch `code-reviewer` on the spec, not on code. Brief: *"Review this spec for executability by a cheaper model that implements literally: find every place it would have to guess — ambiguous interface, missing pattern reference, criterion that is not pass/fail, step that silently assumes knowledge of the code, missing stop condition, a UI step without a layout or a reference screen. Check the referenced paths and signatures against the repo. Do not review the design direction; it is agreed."* Fix the spec for each finding yourself; a finding that reopens a user decision goes back to the user.

### 5. Hand off

Tell the user, in one short message: the spec path, the frozen test files, and the next step — `/build <spec path>`. Do not summarize the spec; they just designed it with you.

Do not implement anything beyond the acceptance tests. Do not commit.
