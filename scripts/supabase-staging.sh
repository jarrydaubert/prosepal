#!/usr/bin/env bash
set -euo pipefail

PRODUCTION_REF="mwoxtqxzunsjmbdqezif"
STAGING_REF="llolwgqphwnhbiqewmcq"

usage() {
  cat <<'USAGE'
Usage:
  scripts/supabase-staging.sh deploy-functions <function-name> [function-name...]
  scripts/supabase-staging.sh db-push

Human-run guarded wrapper for ProsePal staging Supabase operations.

Required for db-push:
  STAGING_DB_URL must be supplied by the operator's shell environment.

Safety rules:
  - Never uses supabase db push --linked.
  - Never runs remote db reset, migration up, or migration down.
  - Never prints STAGING_DB_URL.
  - Refuses if local Supabase link state points at production.
USAGE
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

refuse_production_ref() {
  local label="$1"
  local ref="$2"

  [[ -n "$ref" ]] || die "$label is empty"
  [[ "$ref" != "$PRODUCTION_REF" ]] ||
    die "$label resolves to the production ref ($PRODUCTION_REF)"
}

check_local_supabase_link() {
  local link_file="supabase/.temp/project-ref"

  if [[ ! -f "$link_file" ]]; then
    printf 'Local Supabase link: none found at %s\n' "$link_file"
    return
  fi

  local local_ref
  local_ref="$(tr -d '[:space:]' < "$link_file")"
  refuse_production_ref "Local Supabase link" "$local_ref"

  if [[ "$local_ref" != "$STAGING_REF" ]]; then
    die "Local Supabase link is unexpected ($local_ref). Delete supabase/.temp or relink to staging before staging work."
  fi

  printf 'Local Supabase link: %s\n' "$local_ref"
}

require_staging_target() {
  refuse_production_ref "Declared staging target" "$STAGING_REF"
  [[ "$STAGING_REF" == "llolwgqphwnhbiqewmcq" ]] ||
    die "Script staging ref has been changed unexpectedly"
  printf 'Resolved target ref: %s\n' "$STAGING_REF"
}

require_staging_db_url() {
  [[ -n "${STAGING_DB_URL:-}" ]] ||
    die "STAGING_DB_URL must be set in the operator shell environment"

  [[ "$STAGING_DB_URL" != *"$PRODUCTION_REF"* ]] ||
    die "STAGING_DB_URL contains the production ref; refusing"

  if [[ "$STAGING_DB_URL" != *"$STAGING_REF"* ]]; then
    die "STAGING_DB_URL does not contain the expected staging ref ($STAGING_REF). Update/confirm the URL form before continuing."
  fi
}

print_redacted_db_target() {
  local host
  host="$(printf '%s' "$STAGING_DB_URL" | sed -E 's#^[a-zA-Z0-9+.-]+://([^/@]+@)?([^/:?]+).*#\2#')"

  [[ -n "$host" && "$host" != "$STAGING_DB_URL" ]] ||
    die "Could not safely parse STAGING_DB_URL host; refusing to continue"

  printf 'Resolved DB target host: %s\n' "$host"
  printf 'Resolved DB credential: redacted\n'
}

deploy_functions() {
  [[ "$#" -gt 0 ]] || die "At least one function name is required"
  require_command supabase
  require_staging_target
  check_local_supabase_link

  supabase functions deploy "$@" --project-ref "$STAGING_REF"
}

push_db() {
  [[ "$#" -eq 0 ]] || die "db-push does not accept extra arguments"
  require_command supabase
  require_staging_target
  check_local_supabase_link
  require_staging_db_url
  print_redacted_db_target

  printf 'Running staging DB dry run first...\n'
  supabase db push --db-url "$STAGING_DB_URL" --dry-run

  printf 'Type the exact staging ref (%s) to run the real staging DB push: ' "$STAGING_REF" >&2
  local confirmation
  IFS= read -r confirmation
  [[ "$confirmation" == "$STAGING_REF" ]] ||
    die "Confirmation did not match staging ref; aborting"

  printf 'Running real staging DB push with explicit db-url target...\n'
  supabase db push --db-url "$STAGING_DB_URL"
}

main() {
  local command="${1:-}"
  if [[ -z "$command" ]]; then
    usage
    exit 64
  fi
  shift

  case "$command" in
    deploy-functions)
      deploy_functions "$@"
      ;;
    db-push)
      push_db "$@"
      ;;
    -h|--help|help)
      usage
      ;;
    *)
      usage
      die "Unknown command: $command"
      ;;
  esac
}

main "$@"
