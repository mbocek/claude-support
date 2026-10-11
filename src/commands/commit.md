---
allowed-tools: Bash(git:*), Bash(cat:*), Bash(echo:*), AskUserQuestion
description: Create a git commit following project conventions
---

## Context

- Current git status: !`git status`
- Staged changes: !`git diff --cached --stat`
- Unstaged changes: !`git diff --stat`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10 2>/dev/null || echo "(no commits yet)"`

## Commit conventions

- **Format**: commitizen — `<type>(<scope>): <description>`
- **Types**: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `ci`, `perf`, `style`
- **Scope**: the module or bounded context affected — reuse the scopes this repo's recent commits already use
- **Description**: lowercase, imperative mood, no period at end
- **No AI attribution**: never add Co-Authored-By or any AI/Claude mentions
- **Atomic**: each commit should represent one complete, working change
- **Do NOT commit**: `.env`, credentials, secrets, large binaries, or `node_modules`

## Your task

Based on the above changes, create a single git commit.

1. Read the diff of the files that matter (`git diff [--cached] -- <path>`) to determine the correct type and scope — the stats above are only the index
2. Write a concise commit message (1-2 lines) that focuses on the "why" not the "what"
3. **Show the proposed commit message to the user** and ask if they want to proceed, edit it, or cancel
4. Wait for user confirmation — only then stage the relevant files and create the commit

Use a HEREDOC for the commit message to preserve formatting:
```
git commit -m "$(cat <<'EOF'
<type>(<scope>): <description>

<optional body — only if the change is non-obvious>
EOF
)"
```

Do not use any other tools besides git commands and AskUserQuestion.
