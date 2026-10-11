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

- **The command does the work; agents are for what it cannot do itself.** `/poc` and `/feature` plan, implement, and verify inline. A subagent is dispatched only where a *separate* context genuinely beats the author's — reconnaissance too broad to hold, or a review that must not be the author's own. That is why the agent set is small.
- **Independence, not model tier, is what makes a review worth its cost.** A reviewer arrives with a clean context and an adversarial brief instead of the author's belief that the code is correct. `/feature` therefore hard-wires `security-reviewer` to sensitive surfaces rather than leaving it to self-assessment.
- **Roles by phase, not by stack.** Stack specifics live in each project's guide file, which every agent reads first — so the same set works in any repo.
- **The session sets the dial; commands never override it** *(Claude Code only)*. No command pins `model` or `effort`, so `/model` and `/effort` stay the global cost dials. Only agents pin a model — Haiku for mechanical work, Opus for review and root-cause, Fable for escalation.
- **Effort pinned only where quality must not follow the session** *(Claude Code only)*. `effort` in frontmatter overrides the session level, so every pin takes that agent off the `/effort` dial. The 5.5 models [default to `medium`](https://code.claude.com/docs/en/model-config#adjust-effort-level), so the reviewers pin `high`: a review that silently drops to `medium` is the cheapest place to lose quality. The debugger and the consultant pin `xhigh`; `scout` follows the session.
- **Cost scales with the change.** `/poc` runs with no agents at all; `/feature` adds tests, e2e, and reviewers — but only the reviewers the diff actually triggers.

Typical flow: `/brainstorm` → `/feature` → `/commit`, with `/poc` as a fast lane and `/debug` / `/consult` as escalations.

## Agents

`effort` below is the frontmatter override; *session* means the agent inherits whatever `/effort` is set to.

| Agent | Model / effort | Access | Role |
|-------|----------------|--------|------|
| `scout` | haiku / *session* | read-only | Fast reconnaissance — locates code, maps conventions |
| `code-reviewer` | opus / high | read-only | Verification gate — correctness, concurrency, contracts |
| `security-reviewer` | opus / high | read-only | Adversarial review — injection, authN/Z, secrets, trust boundaries |
| `debugger` | opus / xhigh | write | Root-cause analysis; fixes only on request |
| `fable-consultant` | fable / xhigh | read-only | Escalation-only second opinion; invoked via `/consult` |

## Commands

| Command | Description |
|---------|-------------|
| `/brainstorm` | Sparring-partner ideation before the "what" is decided; runs inline (`scout` for ground truth, `fable-consultant` for a hard call) and ends in an artifact that feeds `/poc` or `/feature` |
| `/feature` | The disciplined lane, run inline on the session model: plan → **conditional approval gate** → implement → tests and e2e → review → fix loop → docs. Dispatches `security-reviewer` (mandatory on sensitive surfaces) and `code-reviewer` (large or contract-changing diffs); otherwise reviews its own diff. Accepts a `/brainstorm` or `/poc` handoff |
| `/poc` | Fast lane to a minimal working prototype — built inline with no subagents, no tests, no review; hands off to `/feature` to harden |
| `/debug` | Structured debugging: reproduce → hypothesize → bisect → root cause; fix only on approval |
| `/consult` | Escalation to `fable-consultant` with an enforced briefing protocol |
| `/bootstrap-project` | Audits or creates the project's guide file from the contract template |
| `/commit` | Git commit following [commitizen](https://commitizen-tools.github.io/commitizen/) conventions, with no AI attribution |

## Targets

The source is authored once with a tool-neutral frontmatter and three tokens — `{{GUIDE}}` (guide file), `{{CFG}}` (config dir), and `{{MEMORY_PROTOCOL}}` (a line pointing at the shared memory protocol). `install.sh` renders it per target:

| | Claude Code | opencode |
|---|---|---|
| Config dir | `.claude/` | `.opencode/` |
| Guide file | `CLAUDE.md` | `AGENTS.md` |
| Tool access | `tools:` allowlist | `permission:` map (derived) |
| Per-agent model / effort | applied | dropped (uses opencode default) |
| Agent-memory protocol | built in (lines dropped) | `agent-memory/_shared/protocol.md` |

For Claude Code the frontmatter is emitted as-is. For opencode the installer drops `name`/`model`/`effort`, adds `mode: subagent`, derives `permission:` from the `tools:` list, and gives commands `agent: build`.

**opencode caveats:** no per-agent model tiering or reasoning effort; orchestration is best-effort (parallel fan-out may run sequentially). Agent memory still works — it is a prompt-driven file convention.

## Layout

```
src/
  agents/*.md      # 5 agents, tool-neutral frontmatter
  commands/*.md    # 7 slash commands
  templates/       # guide-file contract template
  memory/          # agent-memory protocol (opencode only)
install.sh         # renders src/ into .claude/ or .opencode/
```

The guide file (`CLAUDE.md` / `AGENTS.md`) is where each project supplies its stack, commands, conventions, and boundaries — see [`src/templates/project-guide-template.md`](src/templates/project-guide-template.md). Agents with `memory: project` persist durable findings — in Claude Code through its built-in agent memory, in opencode per [`src/memory/protocol.md`](src/memory/protocol.md). Enabling memory grants Write/Edit even for read-only roles, so read-only is enforced by the prompt.

## Manual install

Clone and run the installer locally — it uses the checked-out `src/` directly:

```bash
git clone git@github.com:mbocek/claude-support.git /tmp/claude-support
bash /tmp/claude-support/install.sh opencode   # or: claude / both
```

## License

MIT
