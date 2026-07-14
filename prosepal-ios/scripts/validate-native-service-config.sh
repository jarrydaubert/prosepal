#!/bin/sh

set -eu

if [ "${ACTION:-}" != "install" ] && [ "${PROSEPAL_REQUIRE_REMOTE_CONFIG:-NO}" != "YES" ]; then
  exit 0
fi

fail() {
  echo "error: $1" >&2
  exit 1
}

require_https() {
  name="$1"
  value="$2"

  [ -n "$value" ] || fail "$name is required for archived ProsePal builds."
  case "$value" in
    https://*) ;;
    *) fail "$name must use HTTPS for archived ProsePal builds." ;;
  esac
}

require_https "PROSEPAL_GATEWAY_URL" "${PROSEPAL_GATEWAY_URL:-}"
require_https "PROSEPAL_SUPABASE_URL" "${PROSEPAL_SUPABASE_URL:-}"

supabase_publishable_key="${PROSEPAL_SUPABASE_ANON_KEY:-}"
[ -n "$supabase_publishable_key" ] ||
  fail "PROSEPAL_SUPABASE_ANON_KEY is required for archived ProsePal builds."

case "$supabase_publishable_key" in
  sb_publishable_?*) ;;
  eyJ*)
    first_segment="${supabase_publishable_key%%.*}"
    remaining_segments="${supabase_publishable_key#*.}"
    [ "$remaining_segments" != "$supabase_publishable_key" ] ||
      fail "PROSEPAL_SUPABASE_ANON_KEY must be a Supabase publishable or legacy anon key."
    second_segment="${remaining_segments%%.*}"
    third_segment="${remaining_segments#*.}"
    [ "$third_segment" != "$remaining_segments" ] ||
      fail "PROSEPAL_SUPABASE_ANON_KEY must be a Supabase publishable or legacy anon key."
    [ -n "$first_segment" ] && [ -n "$second_segment" ] && [ -n "$third_segment" ] ||
      fail "PROSEPAL_SUPABASE_ANON_KEY must be a Supabase publishable or legacy anon key."
    case "$third_segment" in
      *.*) fail "PROSEPAL_SUPABASE_ANON_KEY must be a Supabase publishable or legacy anon key." ;;
    esac
    ;;
  *) fail "PROSEPAL_SUPABASE_ANON_KEY must be a Supabase publishable or legacy anon key." ;;
esac

[ -z "${PROSEPAL_DEV_GATEWAY_SECRET:-}" ] ||
  fail "PROSEPAL_DEV_GATEWAY_SECRET must never be embedded in an archived app."

echo "Native remote-service configuration validated for archive."
