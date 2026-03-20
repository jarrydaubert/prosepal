#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

MODE="full"
if [ "${1:-}" = "--repo-only" ]; then
  MODE="repo_only"
  shift
fi

PROJECT_ID="${1:-$(gcloud config get-value project 2>/dev/null || true)}"

remote_config_template="$REPO_ROOT/docs/REMOTE_CONFIG_TEMPLATE.json"
firebase_remote_config_template="$REPO_ROOT/docs/REMOTE_CONFIG_TEMPLATE.firebase.json"
ai_config_file="$REPO_ROOT/lib/core/config/ai_config.dart"

required_remote_config_keys=(
  config_schema_version
  ai_enabled
  paywall_enabled
  premium_enabled
  ai_model
  ai_model_fallback
  ai_use_limited_app_check_tokens
  force_update_enabled
  min_app_version_ios
  min_app_version_android
)

extract_dart_string_constant() {
  local constant_name="$1"
  sed -nE "s/.*static const String ${constant_name} = '([^']+)'.*/\1/p" "$ai_config_file" | head -n1
}

repo_fail=0
default_model="$(extract_dart_string_constant "defaultModel")"
default_fallback_model="$(extract_dart_string_constant "defaultFallbackModel")"

echo "Auditing AI cost/abuse controls (mode: $MODE)"
echo ""
echo "Repo config checks:"

if [ -f "$remote_config_template" ]; then
  echo "  [PASS] docs/REMOTE_CONFIG_TEMPLATE.json exists"
else
  echo "  [FAIL] docs/REMOTE_CONFIG_TEMPLATE.json missing"
  repo_fail=1
fi

if [ -f "$firebase_remote_config_template" ]; then
  echo "  [PASS] docs/REMOTE_CONFIG_TEMPLATE.firebase.json exists"
else
  echo "  [FAIL] docs/REMOTE_CONFIG_TEMPLATE.firebase.json missing"
  repo_fail=1
fi

if [ -z "$default_model" ] || [ -z "$default_fallback_model" ]; then
  echo "  [FAIL] Could not extract AI defaults from lib/core/config/ai_config.dart"
  repo_fail=1
fi

if [ "$repo_fail" -eq 0 ]; then
  for key in "${required_remote_config_keys[@]}"; do
    if jq -e --arg key "$key" 'has($key)' "$remote_config_template" >/dev/null; then
      echo "  [PASS] JSON template includes $key"
    else
      echo "  [FAIL] JSON template missing $key"
      repo_fail=1
    fi

    if jq -e --arg key "$key" '.parameters | has($key)' "$firebase_remote_config_template" >/dev/null; then
      echo "  [PASS] Firebase template includes $key"
    else
      echo "  [FAIL] Firebase template missing $key"
      repo_fail=1
    fi
  done

  if [ "$(jq -r '.ai_enabled' "$remote_config_template")" = "true" ] &&
    [ "$(jq -r '.paywall_enabled' "$remote_config_template")" = "true" ] &&
    [ "$(jq -r '.premium_enabled' "$remote_config_template")" = "true" ]; then
    echo "  [PASS] JSON template keeps AI/paywall/premium kill switches enabled by default"
  else
    echo "  [FAIL] JSON template kill-switch defaults are not all enabled"
    repo_fail=1
  fi

  if [ "$(jq -r '.parameters.ai_enabled.defaultValue.value' "$firebase_remote_config_template")" = "true" ] &&
    [ "$(jq -r '.parameters.paywall_enabled.defaultValue.value' "$firebase_remote_config_template")" = "true" ] &&
    [ "$(jq -r '.parameters.premium_enabled.defaultValue.value' "$firebase_remote_config_template")" = "true" ]; then
    echo "  [PASS] Firebase template keeps AI/paywall/premium kill switches enabled by default"
  else
    echo "  [FAIL] Firebase template kill-switch defaults are not all enabled"
    repo_fail=1
  fi

  json_model="$(jq -r '.ai_model' "$remote_config_template")"
  firebase_model="$(jq -r '.parameters.ai_model.defaultValue.value' "$firebase_remote_config_template")"
  if [ "$json_model" = "$default_model" ] && [ "$firebase_model" = "$default_model" ]; then
    echo "  [PASS] Primary AI model is pinned to code default ($default_model)"
  else
    echo "  [FAIL] Primary AI model template/default mismatch"
    repo_fail=1
  fi

  json_fallback_model="$(jq -r '.ai_model_fallback' "$remote_config_template")"
  firebase_fallback_model="$(
    jq -r '.parameters.ai_model_fallback.defaultValue.value' "$firebase_remote_config_template"
  )"
  if [ "$json_fallback_model" = "$default_fallback_model" ] &&
    [ "$firebase_fallback_model" = "$default_fallback_model" ]; then
    echo "  [PASS] Fallback AI model is pinned to code default ($default_fallback_model)"
  else
    echo "  [FAIL] Fallback AI model template/default mismatch"
    repo_fail=1
  fi
fi

if [ "$MODE" = "repo_only" ]; then
  echo ""
  if [ "$repo_fail" -eq 0 ]; then
    echo "AI cost/abuse audit (repo-only): PASS"
  else
    echo "AI cost/abuse audit (repo-only): FAIL"
  fi
  exit "$repo_fail"
fi

if [ -z "$PROJECT_ID" ]; then
  echo "Error: no GCP project set. Pass project id or run:"
  echo "  gcloud config set project <project-id>"
  echo "  ./scripts/audit_ai_cost_controls.sh --repo-only"
  if [ "$repo_fail" -ne 0 ]; then
    exit "$repo_fail"
  fi
  exit 2
fi

echo "Live project checks for project: $PROJECT_ID"

tmp_keys="$(mktemp)"
tmp_services="$(mktemp)"

cleanup() {
  rm -f "$tmp_keys" "$tmp_services"
}
trap cleanup EXIT

gcloud services api-keys list --project="$PROJECT_ID" --format=json >"$tmp_keys"
gcloud services list --enabled --project="$PROJECT_ID" --format=json >"$tmp_services"

required_services=(
  firebasevertexai.googleapis.com
  firebaseappcheck.googleapis.com
  firebaseremoteconfig.googleapis.com
  playintegrity.googleapis.com
  monitoring.googleapis.com
)

echo ""
echo "Service checks:"
service_fail=0
for svc in "${required_services[@]}"; do
  if jq -e --arg svc "$svc" '.[] | select(.config.name == $svc)' "$tmp_services" >/dev/null; then
    echo "  [PASS] $svc enabled"
  else
    echo "  [FAIL] $svc not enabled"
    service_fail=1
  fi
done

echo ""
echo "API key restriction checks:"
key_fail=0

key_count="$(jq 'length' "$tmp_keys")"
if [ "$key_count" -eq 0 ]; then
  echo "  [FAIL] No API keys found in project."
  key_fail=1
else
  while IFS= read -r key_b64; do
    key_json="$(echo "$key_b64" | base64 --decode)"
    display_name="$(echo "$key_json" | jq -r '.displayName // "Unnamed key"')"

    api_target_count="$(echo "$key_json" | jq '(.restrictions.apiTargets // []) | length')"
    if [ "$api_target_count" -gt 0 ]; then
      echo "  [PASS] $display_name has API target restrictions"
    else
      echo "  [FAIL] $display_name has no API target restrictions"
      key_fail=1
    fi

    case "$display_name" in
      *"Android key"*)
        android_restrictions="$(echo "$key_json" | jq -c '.restrictions.androidKeyRestrictions // {}')"
        if [ "$android_restrictions" != "{}" ]; then
          echo "  [PASS] $display_name has Android app restrictions"
        else
          echo "  [FAIL] $display_name missing Android app restrictions"
          key_fail=1
        fi
        ;;
      *"iOS key"*)
        ios_restrictions="$(echo "$key_json" | jq -c '.restrictions.iosKeyRestrictions // {}')"
        if [ "$ios_restrictions" != "{}" ]; then
          echo "  [PASS] $display_name has iOS app restrictions"
        else
          echo "  [FAIL] $display_name missing iOS app restrictions"
          key_fail=1
        fi
        ;;
      *"Browser key"*)
        browser_restrictions="$(echo "$key_json" | jq -c '.restrictions.browserKeyRestrictions // {}')"
        if [ "$browser_restrictions" != "{}" ]; then
          echo "  [PASS] $display_name has browser restrictions"
        else
          echo "  [FAIL] $display_name missing browser restrictions"
          key_fail=1
        fi

        has_localhost_referrer="$(
          echo "$key_json" | jq -r '
            (
              (.restrictions.browserKeyRestrictions.allowedReferrers // [])
              | map(test("localhost|127\\.0\\.0\\.1"))
              | any
            ) // false
          '
        )"
        if [ "$has_localhost_referrer" = "true" ]; then
          echo "  [FAIL] $display_name allows localhost/127.0.0.1 referrers"
          key_fail=1
        else
          echo "  [PASS] $display_name excludes localhost/127.0.0.1 referrers"
        fi
        ;;
    esac

    uses_generative_language="$(
      echo "$key_json" | jq -r '
        ((.restrictions.apiTargets // []) | map(.service) | index("generativelanguage.googleapis.com")) != null
      '
    )"
    if [ "$uses_generative_language" = "true" ]; then
      echo "  [PASS] $display_name constrained to Generative Language API"

      has_app_restriction="$(
        echo "$key_json" | jq -r '
          (
            (.restrictions.androidKeyRestrictions // null) != null or
            (.restrictions.iosKeyRestrictions // null) != null or
            (.restrictions.browserKeyRestrictions // null) != null or
            (.restrictions.serverKeyRestrictions // null) != null
          )
        '
      )"

      if [ "$display_name" != "Gemini Developer API key (auto created by Firebase)" ] && [ "$has_app_restriction" != "true" ]; then
        echo "  [FAIL] $display_name is a non-Firebase Gemini key without app/server restrictions"
        key_fail=1
      fi
    fi
  done < <(jq -r '.[] | @base64' "$tmp_keys")
fi

echo ""
echo "Budget checks:"
budget_fail=0
billing_account="$(
  gcloud billing accounts list --format=json 2>/dev/null |
    jq -r '.[] | select(.open == true) | .name' |
    sed 's#billingAccounts/##' |
    head -n1
)"

if [ -z "$billing_account" ]; then
  echo "  [WARN] Could not determine an open billing account from current credentials."
  budget_fail=1
else
  if ! gcloud billing budgets list --billing-account="$billing_account" --format=json >/tmp/prosepal-budgets.json 2>/tmp/prosepal-budgets.err; then
    echo "  [FAIL] Could not list budgets for billing account $billing_account"
    echo "         $(cat /tmp/prosepal-budgets.err | head -n1)"
    budget_fail=1
  else
    budget_count="$(jq 'length' /tmp/prosepal-budgets.json)"
    if [ "$budget_count" -gt 0 ]; then
      echo "  [PASS] Found $budget_count budget(s) on billing account $billing_account"
    else
      echo "  [FAIL] No budgets found on billing account $billing_account"
      budget_fail=1
    fi
  fi
fi

overall_fail=0
if [ "$repo_fail" -ne 0 ] ||
  [ "$service_fail" -ne 0 ] ||
  [ "$key_fail" -ne 0 ] ||
  [ "$budget_fail" -ne 0 ]; then
  overall_fail=1
fi

echo ""
if [ "$overall_fail" -eq 0 ]; then
  echo "AI cost/abuse audit: PASS"
else
  echo "AI cost/abuse audit: FAIL"
  echo "Review docs/DEVOPS.md and remediate failures."
fi

exit "$overall_fail"
