# Agent commands

| Command | Scope | May edit? |
|---|---|---|
| `/audit [target]` | Risk-first code/architecture review | No |
| `/sec-review [scope]` | Trust-boundary review | No |
| `/cleanup [scope]` | Proven dead-code/dependency review | No |
| `/test [scope]` | Regression coverage | Within task scope |

[AGENTS](../../AGENTS.md) is canonical; [RUNBOOK](../../docs/RUNBOOK.md) owns commands.
The matching `.agents/skills/` entries point here; do not duplicate workflows.
