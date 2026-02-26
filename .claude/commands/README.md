# Custom Commands

Only these slash commands are active in this repo.

## Active Commands

| Command | Purpose | Writes Code? |
|---------|---------|--------------|
| `/audit [target]` | Deep architecture/code audit with risk-first findings | No |
| `/security [scope]` | Security-focused review and hardening guidance | No |
| `/test [scope]` | Test gap analysis and test implementation support | Yes |
| `/cleanup` | Dead code/dependency cleanup audit | No |

## Usage Examples

```bash
/audit auth
/security payments
/test integration
/cleanup
```

## Operational Rules

- Keep findings actionable and prioritized by severity.
- Do not store progress/status in docs; open work belongs in `docs/BACKLOG.md`.
- Use `docs/DEVOPS.md` for CI/test/release runbook and validation commands.
- Use absolute file paths and line references in findings when possible.
