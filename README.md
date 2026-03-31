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
| `/bootstrap-go-module` | Scaffold a new Go microservice with PostgreSQL, chi router, and testcontainers |
| `/idea-modules` | Sync IntelliJ IDEA `modules.xml` with project subdirectories |

### `/commit`

Analyzes staged and unstaged changes, determines the appropriate type and scope, and produces an atomic commit with a concise, imperative-mood message. No AI attribution is added.

### `/bootstrap-go-module`

Interactively scaffolds a new Go microservice as a subdirectory of the current project. Asks for service name, module path, bounded context, entity, and table name, then generates the full directory structure with domain layer (aggregate, repository, service), HTTP transport (chi router, handlers, DTOs), database migrations, platform packages (config, logger, graceful shutdown), testcontainers integration test infra, Makefile, Dockerfile, and linter config. Runs `go mod tidy`, installs tools, and verifies the generated code passes linting.

### `/idea-modules`

Scans the project root for subdirectories, creates missing `.iml` module files, registers them in `.idea/modules.xml`, and removes entries for directories that no longer exist.

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
