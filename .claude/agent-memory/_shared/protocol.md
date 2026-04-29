# Agent Memory Protocol

Shared memory protocol used by all agents in this project. Each agent has its own memory directory at `.claude/agent-memory/<agent-name>/` and follows the rules below.

## Memory types

- **user** — role, preferences, knowledge. Tailor responses to who they are.
- **feedback** — corrections AND confirmed approaches. Include **Why:** (the reason) and **How to apply:** (when this kicks in) lines so future-you can judge edge cases.
- **project** — ongoing work, decisions, initiatives, deadlines. Convert relative dates to absolute (e.g. "Thursday" → "2026-03-05"). Include **Why:** and **How to apply:** lines.
- **reference** — pointers to external systems and resources.

## What NOT to save

- Code patterns, conventions, architecture, file paths — derivable from the codebase.
- Git history or who-changed-what — `git log` / `git blame` are authoritative.
- Debugging recipes — the fix is in the code.
- Anything already in CLAUDE.md.
- Ephemeral task state — that belongs in tasks/plans, not memory.

These exclusions apply even when explicitly asked to save. Push back and ask what was *surprising* or *non-obvious*.

## File format

Each memory is its own `.md` file with frontmatter:

```markdown
---
name: {{short title}}
description: {{one-line, specific — used to decide relevance later}}
type: {{user|feedback|project|reference}}
---

{{body — for feedback/project, structure as: rule/fact, then **Why:** and **How to apply:** lines}}
```

After saving, add a one-line pointer in `MEMORY.md`:
`- [Title](file.md) — short hook`

`MEMORY.md` is the index, not a memory. No frontmatter. Keep entries under ~150 chars each — content past line ~150 of MEMORY.md may be truncated when loaded into agent context.

## Rules

- Update existing memories instead of duplicating. Search before writing.
- Organize by topic, not chronology.
- Verify paths/functions/flags from memory still exist before recommending them — memories can go stale.
- Trust current code over stale memory. If they conflict, update or delete the memory.
- Remove memories that are wrong, outdated, or no longer load-bearing.

## When to access memory

- When starting work in this agent: read `MEMORY.md` to load context.
- When the user references prior conversations or asks you to recall.
- When a question seems to overlap with stored knowledge.
- When the user explicitly says "ignore memory": don't apply, cite, or reference stored memories.

## Memory vs other persistence

- **Plan**: alignment on approach for current task → use plan, not memory.
- **Tasks**: progress tracking inside one session → use tasks, not memory.
- **Memory**: things that should outlive this conversation.
