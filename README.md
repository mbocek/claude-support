# claude-support

A generic, stack-agnostic agent set plus the commands that orchestrate it, for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## Install

Run from your project root:

```bash
curl -fsSL https://raw.githubusercontent.com/mbocek/claude-support/main/install.sh | bash
```

This copies `agents/`, `commands/`, and `templates/` into `.claude/` (needs `curl`/`tar`). Then run `/bootstrap-project` to set up the `CLAUDE.md` the agents rely on.

Re-running replaces those three directories wholesale; your own files, including saved memories under `.claude/agent-memory/<agent>/`, are left untouched.

From a clone, `bash /path/to/claude-support/install.sh` uses the checked-out files directly.

## Design

- **The command does the work; agents are for what it cannot do itself.** `/poc` and `/feature` plan, implement, and verify inline. A subagent is dispatched only where a *separate* context genuinely beats the author's — reconnaissance too broad to hold, or a review that must not be the author's own. That is why the agent set is small.
- **Independence, not model tier, is what makes a review worth its cost.** A reviewer arrives with a clean context and an adversarial brief instead of the author's belief that the code is correct. `/feature` therefore hard-wires `security-reviewer` to sensitive surfaces rather than leaving it to self-assessment.
- **Roles by phase, not by stack.** Stack specifics live in each project's `CLAUDE.md`, which every agent reads first — so the same set works in any repo.
- **The session sets the dial; commands never override it**. No command pins `model` or `effort`, so `/model` and `/effort` stay the global cost dials. Only agents pin a model — Haiku for mechanical work, Opus for review and root-cause, Fable for escalation.
- **Effort pinned only where quality must not follow the session**. `effort` in frontmatter overrides the session level, so every pin takes that agent off the `/effort` dial. The 5.5 models [default to `medium`](https://code.claude.com/docs/en/model-config#adjust-effort-level), so the reviewers pin `high`: a review that silently drops to `medium` is the cheapest place to lose quality. The debugger and the consultant pin `xhigh`; `scout` follows the session.
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
| `/bootstrap-project` | Audits or creates the project's `CLAUDE.md` from the contract template |
| `/commit` | Git commit following [commitizen](https://commitizen-tools.github.io/commitizen/) conventions, with no AI attribution |

## Layout

```
agents/*.md      # 5 agents
commands/*.md    # 7 slash commands
templates/       # CLAUDE.md contract template
install.sh       # copies the three directories into .claude/
```

`CLAUDE.md` is where each project supplies its stack, commands, conventions, and boundaries — see [`templates/project-guide-template.md`](templates/project-guide-template.md). Agents with `memory: project` persist durable findings through Claude Code's built-in agent memory. Enabling memory grants Write/Edit even for read-only roles, so read-only is enforced by the prompt.

## License

MIT
