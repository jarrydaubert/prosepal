#!/bin/bash
# Check local links and quoted documentation paths; no implementation ledger.
set -euo pipefail
cd "$(dirname "$0")/.."

python3 - <<'PY'
from pathlib import Path
import re
from urllib.parse import unquote, urlsplit

root = Path.cwd()
files = set(Path('docs').glob('*.md'))
files.update(Path(p) for p in ('AGENTS.md', 'CLAUDE.md', 'README.md', 'SECURITY.md',
                             'prosepal-ios/README.md', 'supabase/README.md', 'design-system/readme.md'))
for directory in ('.agents/skills', '.claude/commands'):
    files.update(Path(directory).rglob('*.md'))
errors = []
for source in sorted(files):
    if not source.is_file():
        errors.append(f'missing document: {source}')
        continue
    content = source.read_text()
    for match in re.finditer(r'\[[^\]\n]*\]\(([^)\n]+)\)', content):
        target = match.group(1).split(' "', 1)[0].strip('<>')
        parsed = urlsplit(target)
        if parsed.scheme or parsed.netloc or not parsed.path:
            continue
        candidate = (source.parent / unquote(parsed.path)).resolve()
        if not candidate.exists():
            errors.append(f'{source}: broken local link: {target}')
    # Backticks containing exact docs paths also occur in agent commands.
    for target in re.findall(r'`(docs/[^`\s]+)`', content):
        if any(char in target for char in '*<$'):
            continue
        if not (root / target.split('#', 1)[0]).exists():
            errors.append(f'{source}: missing documentation path: {target}')
if errors:
    raise SystemExit('\n'.join(errors))
print(f'Documentation links passed ({len(files)} Markdown files checked).')
PY
