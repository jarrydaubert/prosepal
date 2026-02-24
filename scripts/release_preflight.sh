#!/bin/bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/release_preflight.sh <ios|android|all> [--env-file <path>] [--no-env-file]

Checks required release dart-define inputs before build/archive steps.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [ $# -lt 1 ]; then
  usage
  exit 2
fi

PLATFORM="$1"
shift || true

ENV_FILE="$PROJECT_DIR/.env.local"
USE_ENV_FILE=true

while [ $# -gt 0 ]; do
  case "$1" in
    --env-file)
      ENV_FILE="$2"
      shift 2
      ;;
    --no-env-file)
      USE_ENV_FILE=false
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 2
      ;;
  esac
done

case "$PLATFORM" in
  ios|android|all) ;;
  *)
    echo "Invalid platform: $PLATFORM"
    usage
    exit 2
    ;;
esac

if [ "$USE_ENV_FILE" = true ]; then
  if [ ! -f "$ENV_FILE" ]; then
    echo "Error: env file not found: $ENV_FILE"
    exit 1
  fi
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

is_placeholder_value() {
  local value="$1"
  case "$value" in
    *your_*|*your-*|*example*|*placeholder*|*"_here"*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

validate_keys() {
  local label="$1"
  shift
  local missing=()
  local placeholder=()

  for key in "$@"; do
    local value="${!key:-}"
    if [ -z "$value" ]; then
      missing+=("$key")
    elif is_placeholder_value "$value"; then
      placeholder+=("$key")
    fi
  done

  if [ "${#missing[@]}" -gt 0 ]; then
    echo "Error: Missing required values for $label: ${missing[*]}"
    return 1
  fi

  if [ "${#placeholder[@]}" -gt 0 ]; then
    echo "Error: Placeholder values detected for $label: ${placeholder[*]}"
    return 1
  fi

  return 0
}

IOS_KEYS=(
  SUPABASE_URL
  SUPABASE_ANON_KEY
  REVENUECAT_IOS_KEY
  GOOGLE_WEB_CLIENT_ID
  GOOGLE_IOS_CLIENT_ID
)

ANDROID_KEYS=(
  SUPABASE_URL
  SUPABASE_ANON_KEY
  REVENUECAT_ANDROID_KEY
  GOOGLE_WEB_CLIENT_ID
)

case "$PLATFORM" in
  ios)
    validate_keys "iOS release build" "${IOS_KEYS[@]}"
    ;;
  android)
    validate_keys "Android release build" "${ANDROID_KEYS[@]}"
    ;;
  all)
    validate_keys "iOS release build" "${IOS_KEYS[@]}"
    validate_keys "Android release build" "${ANDROID_KEYS[@]}"
    ;;
esac

echo "Release preflight passed for platform: $PLATFORM"
