---
allowed-tools: Bash(mkdir:*), Bash(go:*), Bash(ls:*), Read, Write, Glob, Grep, AskUserQuestion
description: Bootstrap a new Go microservice from the go-service-template
---

## Template

!`cat .claude/templates/go-service-template.md`

## Context

- Current directory: !`pwd`
- Existing subdirectories: !`ls -d */ 2>/dev/null || echo "(empty)"`

## Your task

Bootstrap a new Go microservice based on the template above.

1. **Ask** the user for the following (skip any already provided as arguments):
   - **Service name** — used for directory, go module, and binary name (e.g. `user-api`)
   - **Go module path** — e.g. `github.com/user/user-api` (default: just the service name)
   - **First bounded context name** — the initial domain context (e.g. `user`, `role`)
   - **First aggregate/entity name** — the primary entity in that context (e.g. `user`, `role`)
   - **Database table name** — for the initial migration (e.g. `users`, `roles`)
   - **PostgreSQL DSN** — for config.yaml (default: `postgres://app:app_local@localhost:5432/<service_name>`)

2. **Create the full directory structure** as specified in the template, replacing all `<service-name>`, `<context>`, `<table>`, and similar placeholders with the user's answers.

3. **Generate all source files** from the template — every file listed in the template must be created with placeholders replaced. This includes:
   - `Makefile`, `.golangci.yml`, `.gitignore`, `Dockerfile`, `go.mod`
   - All `cmd/`, `config/`, `db/`, `internal/`, and `testinfra/` files
   - Create a minimal initial migration: `db/migration/000001_create_<table>.up.sql` and `.down.sql`

4. **Run `go mod tidy`** to resolve dependencies and generate `go.sum`.

5. **Run `make install-tools`** to install gotestsum and golangci-lint.

6. **Run `make lint`** to verify the generated code passes linting.

7. Fix any lint or compilation issues before finishing.

Important:
- Create the service as a subdirectory of the current working directory
- Use the exact code from the template — do not invent new patterns or add extra files
- For the initial migration SQL, create a simple CREATE TABLE with `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`, `name TEXT NOT NULL`, `created_at TIMESTAMPTZ NOT NULL DEFAULT now()`, and `updated_at TIMESTAMPTZ NOT NULL DEFAULT now()` — adjust columns to fit the entity name
- Wire up the domain layer in `main.go` (uncomment and fill in the wiring code)
