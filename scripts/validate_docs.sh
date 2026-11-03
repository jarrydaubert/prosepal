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
files.update(p for p in Path('design-system').rglob('*')
             if p.is_file() and p.suffix in ('.md', '.html'))
errors = []
for source in sorted(files):
    if not source.is_file():
        errors.append(f'missing document: {source}')
        continue
    content = source.read_text()
    if source == Path('docs/BACKLOG.md'):
        for number, line in enumerate(content.splitlines(), 1):
            if re.match(r'^\s*-\s*\[[xX]\]', line):
                errors.append(f'{source}:{number}: completed checkbox belongs outside the backlog')
    targets = re.findall(r'\[[^\]\n]*\]\(([^)\n]+)\)', content)
    if source.parts[0] == 'design-system':
        targets.extend(re.findall(r'''\b(?:href|src)\s*=\s*["']([^"']+)["']''', content, re.I))
    for target in targets:
        target = target.split(' "', 1)[0].strip('<>')
        parsed = urlsplit(target)
        if parsed.scheme or parsed.netloc or not parsed.path:
            continue
        # Design examples can use web-root URLs, which are not repository paths.
        if source.parts[0] == 'design-system' and parsed.path.startswith('/'):
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
print(f'Documentation validation passed ({len(files)} Markdown/HTML files checked).')
PY
