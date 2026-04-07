---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git diff:*), Bash(git log:*)
description: Create a git commit following project conventions
---

## Context

- Current git status: !`git status`
- Staged changes: !`git diff --cached`
- Unstaged changes: !`git diff`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10 2>/dev/null || echo "(no commits yet)"`

## Commit conventions

- **Format**: commitizen — `<type>(<scope>): <description>`
- **Types**: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `ci`, `perf`, `style`
- **Scope**: the bounded context or module affected (e.g. `api`, `web`, `infra`, `local`, `pages`, `billing`, `identity`, `ordering`, `menu`, `kitchen`, `notification`)
- **Description**: lowercase, imperative mood, no period at end
- **No AI attribution**: never add Co-Authored-By or any AI/Claude mentions
- **Atomic**: each commit should represent one complete, working change
- **Do NOT commit**: `.env`, credentials, secrets, large binaries, or `node_modules`

## Your task

Based on the above changes, create a single git commit.

1. Analyze the diff to determine the correct type and scope
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
