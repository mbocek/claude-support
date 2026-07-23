# claude-support

A generic, stack-agnostic agent set plus the commands that orchestrate it. One source in [`src/`](src/) installs into either [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (`.claude/`) or [opencode](https://opencode.ai) (`.opencode/`).

## Install

Run from your project root — the argument picks the target (`claude` is the default):

```bash
# Claude Code -> .claude/
curl -fsSL https://raw.githubusercontent.com/mbocek/claude-support/main/install.sh | bash

# opencode -> .opencode/
curl -fsSL https://raw.githubusercontent.com/mbocek/claude-support/main/install.sh | bash -s -- opencode
```

Also accepts `both`. Requires `awk`/`sed` (and `curl`/`tar` when downloading). Then run `/bootstrap-project` to set up the guide file the agents rely on.

Re-running replaces the installed files wholesale; your own files, including saved memories under `<cfg>/agent-memory/<agent>/`, are left untouched.

## Design

- **Roles by phase, not by stack.** Agents map to pipeline stages (recon → design → implementation → verification). Stack specifics live in each project's guide file, which every agent reads first — so the same set works in any repo.
- **Model by leverage** *(Claude Code only)*. Haiku does mechanical work, Sonnet implements, Opus designs and reviews, Fable is escalation-only.
- **Verification asymmetry.** Code is written by a cheaper model and reviewed by a stronger one.

Typical flow: `/brainstorm` → `/feature` → `/commit`, with `/poc` as a fast lane and `/debug` / `/consult` as escalations.

## Agents

| Agent | Model / effort | Access | Role |
|-------|----------------|--------|------|
| `scout` | haiku / low | read-only | Fast reconnaissance — locates code, maps conventions |
| `architect` | opus / high | read-only | Design and planning — boundaries, contracts, ordered steps, risks |
| `implementer` | sonnet / high | write | Writes code following the plan and surrounding conventions |
| `test-engineer` | sonnet / medium | write | Behavior-focused tests using the project's framework |
| `code-reviewer` | opus / high | read-only | Verification gate — correctness, concurrency, contracts |
| `security-reviewer` | opus / high | read-only | Adversarial review — injection, authN/Z, secrets, trust boundaries |
| `debugger` | opus / xhigh | write | Root-cause analysis; fixes only on request |
| `docs-writer` | haiku / low | docs only | READMEs, changelogs, runbooks — verified against the code |
| `fable-consultant` | fable / high | read-only | Escalation-only second opinion; invoked via `/consult` |

## Commands

| Command | Description |
|---------|-------------|
| `/brainstorm` | Sparring-partner ideation before the "what" is decided; ends in an artifact that feeds `/feature` |
| `/feature` | Full pipeline: scout → architect → **plan approval** → implementer → tests → review loop → docs. Accepts a `/brainstorm` or `/poc` handoff |
| `/poc` | Fast lane to a minimal working prototype (no tests, no review); hands off to `/feature` to harden |
| `/debug` | Structured debugging: reproduce → hypothesize → bisect → root cause; fix only on approval |
| `/consult` | Escalation to `fable-consultant` with an enforced briefing protocol |
| `/bootstrap-project` | Audits or creates the project's guide file from the contract template |
| `/commit` | Git commit following [commitizen](https://commitizen-tools.github.io/commitizen/) conventions, with no AI attribution |

## Targets

The source is authored once with a tool-neutral frontmatter and two tokens — `{{GUIDE}}` (guide file) and `{{CFG}}` (config dir). `install.sh` renders it per target:

| | Claude Code | opencode |
|---|---|---|
| Config dir | `.claude/` | `.opencode/` |
| Guide file | `CLAUDE.md` | `AGENTS.md` |
| Tool access | `tools:` allowlist | `permission:` map (derived) |
| Per-agent model / effort | applied | dropped (uses opencode default) |

For Claude Code the frontmatter is emitted as-is. For opencode the installer drops `name`/`model`/`effort`, adds `mode: subagent`, derives `permission:` from the `tools:` list, and gives commands `agent: build`.

**opencode caveats:** no per-agent model tiering or reasoning effort; orchestration is best-effort (parallel fan-out may run sequentially). Agent memory still works — it is a prompt-driven file convention.

## Layout

```
src/
  agents/*.md      # 9 agents, tool-neutral frontmatter
  commands/*.md    # 7 slash commands
  templates/       # guide-file contract template
  memory/          # shared agent-memory protocol
install.sh         # renders src/ into .claude/ or .opencode/
```

The guide file (`CLAUDE.md` / `AGENTS.md`) is where each project supplies its stack, commands, conventions, and boundaries — see [`src/templates/project-guide-template.md`](src/templates/project-guide-template.md). Agents with `memory: project` persist durable findings per [`src/memory/protocol.md`](src/memory/protocol.md); enabling memory grants Write/Edit even for read-only roles, so read-only is enforced by the prompt.

## Manual install

Clone and run the installer locally — it uses the checked-out `src/` directly:

```bash
git clone git@github.com:mbocek/claude-support.git /tmp/claude-support
bash /tmp/claude-support/install.sh opencode   # or: claude / both
```

## License

MIT
