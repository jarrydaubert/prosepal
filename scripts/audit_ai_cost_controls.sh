#!/bin/bash

set -euo pipefail

PROJECT_ID="${1:-$(gcloud config get-value project 2>/dev/null || true)}"

if [ -z "$PROJECT_ID" ]; then
  echo "Error: no GCP project set. Pass project id or run:"
  echo "  gcloud config set project <project-id>"
  exit 2
fi

echo "Auditing AI cost/abuse controls for project: $PROJECT_ID"

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
if [ "$service_fail" -ne 0 ] || [ "$key_fail" -ne 0 ] || [ "$budget_fail" -ne 0 ]; then
  overall_fail=1
fi

echo ""
if [ "$overall_fail" -eq 0 ]; then
  echo "AI cost/abuse audit: PASS"
else
  echo "AI cost/abuse audit: FAIL"
  echo "Review docs/AI_COST_ABUSE_RUNBOOK.md and remediate failures."
fi

exit "$overall_fail"
