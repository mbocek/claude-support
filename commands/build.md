---
allowed-tools: Bash, Read, Grep, Glob, Agent, SendMessage, AskUserQuestion
argument-hint: spec-*.md
description: Execute a /spec on the cheaper implementer, with strong-model review and a fix loop
---

## Context

- Arguments (spec file): $ARGUMENTS
- Current branch: !`git branch --show-current 2>/dev/null || echo "(not a git repo)"`
- Git status: !`git status --short 2>/dev/null || echo "(not a git repo)"`
- HEAD: !`git rev-parse --short HEAD 2>/dev/null || echo "(no commits)"`

## Your task

You coordinate; you do not write code. `implementer` (a cheaper model) writes it, `code-reviewer` (Opus) judges it, and the spec is the contract between them. Keep your own context small: pass paths and refs, never paste files or diffs.

If `$ARGUMENTS` does not name a spec, pick the newest `spec-*.md` in the working directory and say which one; if there is none, tell the user to run `/spec` first.

Work quietly; report once at the end.

### 1. Implement

The HEAD above is the base ref. If the working tree holds anything besides the spec and its frozen test files, say so in one line. The frozen files are untracked, so `git diff` cannot show edits to them: record `shasum` of each before dispatching and compare after every implementer round — a changed hash is a finding. Dispatch **implementer** with the spec path and the base ref.

If it returns **blocked**, the spec did not decide something. Do not resolve it here and do not re-dispatch with your own decision: report the blocker verbatim and tell the user to amend the spec with `/spec`. Stop.

### 2. Verify

Run the spec's acceptance criteria yourself — green means observed green. Send long output to a file and read only the failures. If anything is red, go to step 4 with the failures as the findings.

If the change touches anything a user sees, look at it — nobody else in this pipeline does, and a green build with a clean review says nothing about the screen. Run the app the way the project's `CLAUDE.md` says, drive each changed screen as a user would (open it, switch between records, save, reopen), screenshot it, and read the screenshot next to the reference screen the spec names. Spacing, width, alignment, a control styled unlike its neighbours, or a click that has to be repeated is a finding exactly like a failing test. Re-take the screenshots after every fix round.

### 3. Review

Dispatch **code-reviewer**: the spec path, the base ref, the changed-file list from `git status --short` (it runs `git diff` itself, which misses untracked new files), and the spec's Review focus. Ask it to check the change against the spec — every step done as specified, nothing out of scope, frozen files untouched — besides its usual review. If the spec lists a sensitive surface or the changed files touch one (auth, secrets, payments, user-controlled input, files and paths, deserialization, outbound calls), dispatch **security-reviewer** in the same message so both run in parallel.

### 4. Fix loop

Turn each finding above nit level into a concrete fix instruction — the reviewer gives a direction, and the implementer must not choose one — and send them to the **same implementer** (SendMessage to its ID or name) with the base ref; if the tool cannot resume a subagent, dispatch a new one with the spec path and the findings. Then re-run the criteria and re-dispatch only the reviewer that raised them as a **delta review**: its own findings verbatim and the ref the fixes start from; it confirms each is resolved and checks the fixes, nothing more.

A finding that shows the spec itself is wrong is not fixed in code: stop and send it to the user for `/spec`. Cap the loop at 2 rounds; findings that survive go into the summary as open.

### 5. Report

One short summary: what was built, the acceptance criteria with real results, the screenshots you checked (paths), the reviewers that ran and their verdicts, files changed, and **Open** — surviving findings, deviations, anything unverified. Do not commit — suggest `/commit`.
