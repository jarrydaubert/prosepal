# Custom Commands

Only these slash commands are active in this repo.

## Active Commands

| Command | Purpose | Writes Code? |
|---------|---------|--------------|
| `/audit [target]` | Deep architecture/code audit with risk-first findings | No |
| `/sec-review [scope]` | Security-focused review and hardening guidance | No |
| `/test [scope]` | Test gap analysis and test implementation support | Yes |
| `/cleanup` | Dead code/dependency cleanup audit | No |

## Usage Examples

```bash
/audit auth
/sec-review payments
/test integration
/cleanup
```

## Operational Rules

- Keep findings actionable and prioritized by severity.
- Do not store progress/status in docs; open work belongs in `docs/BACKLOG.md`.
- Use `docs/quality/testing.md` for test commands and
  `docs/operations/release.md` for release gates.
- Use absolute file paths and line references in findings when possible.
