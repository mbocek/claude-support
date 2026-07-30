# {{GUIDE}} contract template

This template defines the sections a project's `{{GUIDE}}` must provide for the commands and the
generic agent set (scout, code-reviewer, security-reviewer, debugger, fable-consultant) to work
well. They are stack-agnostic by design — this file is where the project supplies the stack. `/bootstrap-project` audits or creates a `{{GUIDE}}` against it.

Keep the real file short and factual: every line should change how an agent behaves. Delete any
section that does not apply rather than leaving placeholder prose.

---

```markdown
# {{GUIDE}}

## What this is

<!-- 2-4 sentences: what the software does, who uses it, and the shape of the system
     (monolith / microservices / CLI / library; monorepo or not). -->

## Stack

<!-- Languages with versions, key frameworks and libraries, database(s), infrastructure.
     One line per item, only load-bearing choices. Example:
     - Go 1.24 — services under services/*, chi router, pgx, zerolog
     - SvelteKit 2 — frontend under web/
     - PostgreSQL 17, Kafka (MSK), Terraform under infra/ -->

## Commands

<!-- The exact commands agents must use. These are the most load-bearing lines in the file. -->
- Build: `<command>`
- Test (all): `<command>`
- Test (single package/file): `<command>`
- E2E / integration suite: `<command>` <!-- or "none" — /feature runs this and needs to know -->
- Lint / format: `<command>`
- Run locally: `<command>`

## Layout

<!-- Only the non-obvious parts: where domains/services/entry points live, what is generated
     (and must not be hand-edited), where tests live relative to code. -->

## Conventions

<!-- Rules an agent cannot infer from one file of the codebase. Examples:
     - Errors: wrap with eris, never fmt.Errorf; sentinel errors in <pkg>/errors.go
     - Tests: testcontainers over mocks for repositories; table-driven tests
     - API: breaking changes to public endpoints require a version bump
     - Commits: commitizen format, no AI attribution -->

## Boundaries

<!-- What agents must not do in this repo without explicit approval. Examples:
     - Never edit files under gen/ or *_gen.go — regenerate instead (`make generate`)
     - Never run migrations against anything but the local database
     - Secrets live in <system>; never hardcode or log them -->

## Verification

<!-- What "done" means here beyond tests passing: e.g. `make verify`, a smoke-test flow,
     required manual checks before a PR. -->
```
