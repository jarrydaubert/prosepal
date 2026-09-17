"""Classify changed paths once for CI, Native UI and CodeQL job gates."""
import json
import os
import re
import subprocess
from pathlib import Path


SHARED_CI = {
    'scripts/ci_scope.py', 'scripts/tests/test_ci_scope.py',
    'scripts/release_preflight.sh', '.github/workflows/change-scope.yml',
    '.github/workflows/ci.yml',
}


def classify(paths):
    if paths is None:  # Scheduled/manual runs or unavailable comparison: full gates.
        return dict(native=True, supabase=True, codeql=True)
    scope = dict(native=False, supabase=False, codeql=False)
    for name in paths:
        path = Path(name)
        if path.suffix.lower() in ('.md', '.rst'):
            continue
        shared = name in SHARED_CI or name.startswith('.github/actions/')
        tool = name.startswith('scripts/')
        scope['native'] |= (shared or name.startswith('prosepal-ios/')
                            or name == '.github/workflows/native-ui.yml'
                            or name in ('.swiftformat', '.swiftlint.yml')
                            or (tool and any(word in path.name for word in ('ios', 'native', 'storekit'))))
        scope['supabase'] |= (shared or name.startswith('supabase/')
                              or name.startswith('.github/workflows/supabase')
                              or path.name in ('deno.json', 'deno.jsonc', 'deno.lock')
                              or (tool and any(word in path.name for word in ('supabase', 'gateway', 'keepalive'))))
        scope['codeql'] |= (shared or name.startswith(('.github/workflows/', '.github/actions/', '.github/codeql/'))
                            or path.suffix in ('.js', '.jsx', '.ts', '.tsx', '.mjs', '.cjs', '.html', '.htm', '.vue', '.svelte')
                            or path.name in ('package.json', 'package-lock.json', 'npm-shrinkwrap.json',
                                             'yarn.lock', 'pnpm-lock.yaml', 'deno.json', 'deno.jsonc', 'deno.lock')
                            or path.name.startswith(('tsconfig', 'jsconfig')))
    return scope


def changed_paths(event_name, event, head):
    if event_name == 'pull_request':
        base = event['pull_request']['base']['sha']
        head = event['pull_request']['head']['sha']
        separator = '...'  # Changes on the PR branch, excluding base-branch drift.
    elif event_name == 'push':
        base = event['before']
        separator = '..'
    else:
        return None
    if not all(re.fullmatch(r'[0-9a-f]{40,64}', sha or '') and set(sha) != {'0'}
               for sha in (base, head)):
        return None
    try:
        result = subprocess.run(['git', 'diff', '--name-only', '--no-renames', '-z',
                                 f'{base}{separator}{head}'], check=True, capture_output=True)
    except subprocess.CalledProcessError:
        print('::warning::Changed paths unavailable; running full validation.')
        return None
    # Disabling rename detection includes both deleted and added paths.
    return os.fsdecode(result.stdout).rstrip('\0').split('\0') if result.stdout else []


if __name__ == '__main__':
    event = json.loads(Path(os.environ['GITHUB_EVENT_PATH']).read_text())
    scope = classify(changed_paths(os.environ['GITHUB_EVENT_NAME'], event, os.environ['GITHUB_SHA']))
    output = ''.join(f'{name}={str(enabled).lower()}\n' for name, enabled in scope.items())
    print(output, end='')
    with open(os.environ['GITHUB_OUTPUT'], 'a') as destination:
        destination.write(output)
