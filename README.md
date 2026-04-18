# claude-support

Reusable [Claude Code](https://docs.anthropic.com/en/docs/claude-code) custom commands and configuration that can be installed into any project.

## Quick Install

Run this one-liner from the root of your project:

```bash
curl -fsSL https://raw.githubusercontent.com/mbocek/claude-support/main/install.sh | bash
```

This downloads the `.claude` directory (commands and config) into your current working directory. Requires `curl` and `jq`.

## Commands

| Command | Description |
|---------|-------------|
| `/commit` | Create a git commit following [commitizen](https://commitizen-tools.github.io/commitizen/) conventions (`<type>(<scope>): <description>`) |
| `/review` | Review uncommitted changes or a full branch diff by dispatching specialized agents in parallel |
| `/brainstorm` | Brainstorm a topic as a sparring partner, with a specialist agent panel and a final markdown artifact |
| `/bootstrap-go-module` | Scaffold a new Go microservice with PostgreSQL, chi router, and testcontainers |
| `/idea-modules` | Sync IntelliJ IDEA `modules.xml` with project subdirectories |

### `/commit`

Analyzes staged and unstaged changes, determines the appropriate type and scope, and produces an atomic commit with a concise, imperative-mood message. No AI attribution is added.

### `/review`

Reviews code changes by dispatching specialized agents in parallel. Auto-detects scope — reviews uncommitted changes if the branch has no commits ahead of the default branch, otherwise reviews the full branch diff. Accepts explicit `changes` / `branch` scope and an optional path filter. Categorizes changed files (Go source, Go tests, frontend, infrastructure) and routes them to the relevant agents (`go-code-reviewer`, `go-test-automation`, `svelte-senior-developer`, `ux-senior-developer`, `aws-infra-architect`, plus `go-senior-developer` and `cloud-native-architect` for architectural/DDD and distributed-systems concerns). Results are aggregated into a priority-grouped summary table (Critical / Important / Minor) followed by per-issue detail. Read-only — no agent modifies files.

### `/brainstorm`

Interactive thinking counterpart for exploring a topic — grows the idea, surfaces weaknesses, and pairs every risk with a mitigation. Takes an optional topic as argument (asks if omitted). Phase 1 dispatches a relevant subset of the specialist agent panel in parallel for opening angles, risks, and clarifying questions; Phase 2 is a conversation where individual agents are pulled in on demand for focused consults; Phase 3 produces a markdown artifact (`brainstorm-<slug>-<date>.md`) with context, core direction, options considered, risks & mitigations, open questions, next steps, and specialist input. Read-only until the final write.

### `/bootstrap-go-module`

Interactively scaffolds a new Go microservice as a subdirectory of the current project. Asks for service name, module path, bounded context, entity, and table name, then generates the full directory structure with domain layer (aggregate, repository, service), HTTP transport (chi router, handlers, DTOs), database migrations, platform packages (config, logger, graceful shutdown), testcontainers integration test infra, Makefile, Dockerfile, and linter config. Runs `go mod tidy`, installs tools, and verifies the generated code passes linting.

### `/idea-modules`

Scans the project root for subdirectories, creates missing `.iml` module files, registers them in `.idea/modules.xml`, and removes entries for directories that no longer exist.

## Agents

Specialized subagents invoked automatically by Claude Code based on context, or explicitly via `@agent-name`.

| Agent | Description |
|-------|-------------|
| `go-senior-developer` | Expert Go development — new features, architecture, debugging, and technology decisions. Applies DDD, KISS, and idiomatic Go with zerolog, chi, pgx, eris, and testify. |
| `go-code-reviewer` | Reviews Go code for correctness, idiomatic style, concurrency safety, performance, and test coverage. Triggered automatically after significant Go code is written or modified. |
| `go-test-automation` | Writes and improves Go tests — unit tests and integration tests with testcontainers. Prefers real containers over mocked repositories. |
| `svelte-senior-developer` | Expert SvelteKit development — architecture, implementation, refactoring, debugging, and code review for Svelte/SvelteKit applications. |
| `ux-senior-developer` | Front-end engineering combined with UX expertise — accessible and responsive UI components, interaction patterns, usability review, and design system alignment. |
| `cloud-native-architect` | Designs and implements microservice architectures, distributed systems, and cloud-native applications — service boundaries, API contracts, resilience patterns, and observability strategies. |
| `aws-infra-architect` | AWS infrastructure design, Terraform code, and cloud cost optimization — VPC design, service selection trade-offs, cost analysis, and production-readiness reviews. |

## Manual Installation

If you prefer not to use the install script:

```bash
# Clone and copy
git clone git@github.com:mbocek/claude-support.git /tmp/claude-support
cp -r /tmp/claude-support/.claude .claude
rm -rf /tmp/claude-support
```

Or symlink for automatic updates:

```bash
git clone git@github.com:mbocek/claude-support.git ~/claude-support
ln -s ~/claude-support/.claude .claude
```

## License

MIT
