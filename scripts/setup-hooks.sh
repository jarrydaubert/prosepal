#!/bin/bash
# Install git hooks for this repository

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$REPO_DIR/.git/hooks"

if [[ ! -d "$HOOKS_DIR" ]]; then
  echo "Git hooks directory not found: $HOOKS_DIR" >&2
  exit 1
fi

echo "Installing git hooks..."

cp "$SCRIPT_DIR/pre-commit" "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/pre-commit"
cp "$SCRIPT_DIR/commit-msg" "$HOOKS_DIR/commit-msg"
chmod +x "$HOOKS_DIR/commit-msg"

echo "✅ Git hooks installed!"
echo "Pre-commit will now run: format + analyze"
echo "Commit-msg will now run: attribution trailer guard"
