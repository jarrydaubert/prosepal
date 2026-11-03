#!/bin/bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/setup_python.sh [--upgrade-tools]

Creates/updates a local .venv using python3 and validates minimum Python version.

Options:
  --upgrade-tools   Upgrade pip/setuptools/wheel inside .venv.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VENV_DIR="$PROJECT_DIR/.venv"
PYTHON_BIN="${PYTHON_BIN:-python3}"
UPGRADE_TOOLS=false
MIN_MAJOR=3
MIN_MINOR=14

while [ $# -gt 0 ]; do
  case "$1" in
    --upgrade-tools)
      UPGRADE_TOOLS=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 2
      ;;
  esac
done

if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
  echo "Error: $PYTHON_BIN is not installed or not on PATH."
  exit 1
fi

read -r PY_MAJOR PY_MINOR < <("$PYTHON_BIN" -c 'import sys; print(sys.version_info.major, sys.version_info.minor)')
if [ "$PY_MAJOR" -lt "$MIN_MAJOR" ] || { [ "$PY_MAJOR" -eq "$MIN_MAJOR" ] && [ "$PY_MINOR" -lt "$MIN_MINOR" ]; }; then
  echo "Error: Python ${MIN_MAJOR}.${MIN_MINOR}+ is required. Found: $("$PYTHON_BIN" --version 2>&1)"
  exit 1
fi

if [ ! -d "$VENV_DIR" ]; then
  "$PYTHON_BIN" -m venv "$VENV_DIR"
  echo "Created virtualenv at $VENV_DIR"
else
  echo "Using existing virtualenv at $VENV_DIR"
fi

VENV_PY="$VENV_DIR/bin/python"
VENV_PIP="$VENV_DIR/bin/pip"

if [ ! -x "$VENV_PY" ]; then
  echo "Error: virtualenv python not found at $VENV_PY"
  exit 1
fi

echo "Virtualenv python: $("$VENV_PY" --version 2>&1)"

if ! "$VENV_PY" -m pip --version >/dev/null 2>&1; then
  "$VENV_PY" -m ensurepip --upgrade
fi

if [ "$UPGRADE_TOOLS" = true ]; then
  "$VENV_PY" -m pip install --upgrade pip setuptools wheel
  echo "Upgraded pip/setuptools/wheel in .venv"
fi

echo "Done. Activate with: source .venv/bin/activate"
if [ -x "$VENV_PIP" ]; then
  echo "Pip path: $VENV_PIP"
else
  echo "Use pip via: $VENV_PY -m pip"
fi
