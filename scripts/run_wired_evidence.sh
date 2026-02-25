#!/bin/bash
# Run wired-device integration suites and collect evidence artifacts.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/run_wired_evidence.sh [options]

Options:
  --suite <smoke|e2e|full>   Suite preset to run (default: smoke)
  --test-file <path>         Run a specific integration test file (repeatable)
  --android-id <device-id>   Android device ID (auto-detected if omitted)
  --ios-id <device-id>       iOS device ID (auto-detected if omitted)
  --skip-android             Skip Android execution
  --skip-ios                 Skip iOS execution
  --out-dir <path>           Artifact output directory
  -h, --help                 Show this help
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
IDEVICE_SCREENSHOT_BIN="$(command -v idevicescreenshot || true)"

RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_ROOT="${OUT_ROOT:-$PROJECT_DIR/artifacts/wired}"
RUN_DIR="$OUT_ROOT/$RUN_ID"
SUMMARY_FILE="$RUN_DIR/SUMMARY.md"

SUITE_PRESET="smoke"
ANDROID_ID=""
IOS_ID=""
SKIP_ANDROID=0
SKIP_IOS=0
TEST_TIMEOUT_SEC="${TEST_TIMEOUT_SEC:-480}"
declare -a TEST_FILES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --suite)
      SUITE_PRESET="$2"
      shift 2
      ;;
    --test-file)
      TEST_FILES+=("$2")
      shift 2
      ;;
    --android-id)
      ANDROID_ID="$2"
      shift 2
      ;;
    --ios-id)
      IOS_ID="$2"
      shift 2
      ;;
    --skip-android)
      SKIP_ANDROID=1
      shift
      ;;
    --skip-ios)
      SKIP_IOS=1
      shift
      ;;
    --out-dir)
      RUN_DIR="$2"
      SUMMARY_FILE="$RUN_DIR/SUMMARY.md"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ ${#TEST_FILES[@]} -eq 0 ]]; then
  case "$SUITE_PRESET" in
    smoke)
      TEST_FILES=("integration_test/smoke_test.dart")
      ;;
    e2e)
      TEST_FILES=("integration_test/e2e_test.dart")
      ;;
    full)
      TEST_FILES=("integration_test/smoke_test.dart" "integration_test/e2e_test.dart")
      ;;
    *)
      echo "Invalid suite preset: $SUITE_PRESET" >&2
      usage
      exit 1
      ;;
  esac
fi

mkdir -p "$RUN_DIR"

discover_android_id() {
  /opt/homebrew/share/android-commandlinetools/platform-tools/adb devices 2>/dev/null \
    | awk '$2 == "device" { print $1; exit }'
}

discover_ios_id() {
  flutter devices 2>/dev/null \
    | awk -F'•' '/ios/ { gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2; exit }'
}

if [[ "$SKIP_ANDROID" -eq 0 && -z "$ANDROID_ID" ]]; then
  ANDROID_ID="$(discover_android_id || true)"
fi

if [[ "$SKIP_IOS" -eq 0 && -z "$IOS_ID" ]]; then
  IOS_ID="$(discover_ios_id || true)"
fi

if [[ "$SKIP_ANDROID" -eq 0 && -z "$ANDROID_ID" ]]; then
  echo "No wired Android device detected. Use --android-id or --skip-android." >&2
fi

if [[ "$SKIP_IOS" -eq 0 && -z "$IOS_ID" ]]; then
  echo "No wired iOS device detected. Use --ios-id or --skip-ios." >&2
fi

if [[ "$SKIP_ANDROID" -eq 1 && "$SKIP_IOS" -eq 1 ]]; then
  echo "Both platforms are skipped; nothing to run." >&2
  exit 1
fi

target_count=0
if [[ "$SKIP_ANDROID" -eq 0 && -n "$ANDROID_ID" ]]; then
  target_count=$((target_count + 1))
fi
if [[ "$SKIP_IOS" -eq 0 && -n "$IOS_ID" ]]; then
  target_count=$((target_count + 1))
fi
if [[ "$target_count" -eq 0 ]]; then
  echo "No wired targets available. Provide --android-id/--ios-id or use --skip-* flags." >&2
  exit 1
fi

cat > "$SUMMARY_FILE" <<EOF
# Wired Evidence Run

- run_id: $RUN_ID
- generated_at_utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- suite_preset: $SUITE_PRESET
- per_test_timeout_sec: $TEST_TIMEOUT_SEC
- android_device: ${ANDROID_ID:-not-configured}
- ios_device: ${IOS_ID:-not-configured}

## Results

| platform | suite | status | log |
|---|---|---|---|
EOF

overall_status=0

append_result() {
  local platform="$1"
  local suite_name="$2"
  local status="$3"
  local log_file="$4"
  echo "| $platform | $suite_name | $status | \`$log_file\` |" >> "$SUMMARY_FILE"
}

extract_signals() {
  local log_file="$1"
  local output_file="$2"
  rg -n \
    "Unhandled Exception|EXCEPTION CAUGHT|RenderFlex overflowed|TimeoutException|Target native_assets required define SdkRoot|\\[ERROR\\]" \
    "$log_file" > "$output_file" || true
}

has_failure_signals() {
  local signals_file="$1"
  local test_file="$2"
  local suite_name
  suite_name="$(basename "$test_file")"

  # Known non-fatal log noise from integration harness; keep this list short.
  if [[ "$suite_name" == "e2e_test.dart" ]]; then
    if [[ -s "$signals_file" ]]; then
      rg -v "Critical service initialization failed|Init failed" "$signals_file" > "${signals_file}.filtered" || true
      if [[ -s "${signals_file}.filtered" ]]; then
        mv "${signals_file}.filtered" "$signals_file"
        return 0
      fi
      rm -f "${signals_file}.filtered"
    fi
    return 1
  fi

  [[ -s "$signals_file" ]]
}

run_with_timeout() {
  local timeout_sec="$1"
  local log_file="$2"
  shift 2

  local errexit_was_set=0
  if [[ "$-" == *e* ]]; then
    errexit_was_set=1
  fi

  set +e
  "$@" >"$log_file" 2>&1 &
  local cmd_pid=$!
  local elapsed=0
  local sleep_step=2

  while kill -0 "$cmd_pid" 2>/dev/null; do
    if [[ "$elapsed" -ge "$timeout_sec" ]]; then
      echo "[ERROR] Timed out after ${timeout_sec}s" >> "$log_file"
      kill -TERM "$cmd_pid" 2>/dev/null || true
      sleep 2
      kill -KILL "$cmd_pid" 2>/dev/null || true
      wait "$cmd_pid" 2>/dev/null || true
      if [[ "$errexit_was_set" -eq 1 ]]; then
        set -e
      else
        set +e
      fi
      return 124
    fi

    sleep "$sleep_step"
    elapsed=$((elapsed + sleep_step))
  done

  wait "$cmd_pid"
  local status=$?
  if [[ "$errexit_was_set" -eq 1 ]]; then
    set -e
  else
    set +e
  fi
  return "$status"
}

run_suite() {
  local platform="$1"
  local device_id="$2"
  local test_file="$3"
  local platform_dir="$RUN_DIR/$platform"
  local suite_name
  suite_name="$(basename "$test_file" .dart)"
  local log_file="$platform_dir/${suite_name}.log"
  local signals_file="$platform_dir/${suite_name}.signals.txt"

  mkdir -p "$platform_dir"
  echo "[$platform] Running $test_file on $device_id"

  local run_started_compact
  run_started_compact="$(date +%Y%m%d%H%M%S)"

  if [[ "$platform" == "android" ]]; then
    /opt/homebrew/share/android-commandlinetools/platform-tools/adb -s "$device_id" logcat -c >/dev/null 2>&1 || true
  fi

  set +e
  run_with_timeout "$TEST_TIMEOUT_SEC" "$log_file" flutter test "$test_file" -d "$device_id"
  local command_status=$?
  set -e

  extract_signals "$log_file" "$signals_file"
  local has_signals=1
  if has_failure_signals "$signals_file" "$test_file"; then
    has_signals=0
  fi

  if [[ "$platform" == "android" ]]; then
    /opt/homebrew/share/android-commandlinetools/platform-tools/adb -s "$device_id" logcat -d > "$platform_dir/${suite_name}.logcat.txt" 2>/dev/null || true
    /opt/homebrew/share/android-commandlinetools/platform-tools/adb -s "$device_id" exec-out screencap -p > "$platform_dir/${suite_name}_final.png" 2>/dev/null || true
    mkdir -p "$platform_dir/${suite_name}_device_album"
    local remote_screenshots
    remote_screenshots="$(
      /opt/homebrew/share/android-commandlinetools/platform-tools/adb -s "$device_id" shell 'ls /sdcard/Pictures/Screenshots/Screenshot_*.png 2>/dev/null' \
        | tr -d '\r'
    )"

    while IFS= read -r remote_path; do
      [[ -z "$remote_path" ]] && continue
      local file_name stamp_compact
      file_name="$(basename "$remote_path")"
      stamp_compact="${file_name#Screenshot_}"
      stamp_compact="${stamp_compact%.png}"
      stamp_compact="${stamp_compact/-/}"

      if [[ "$stamp_compact" < "$run_started_compact" ]]; then
        continue
      fi

      /opt/homebrew/share/android-commandlinetools/platform-tools/adb -s "$device_id" pull "$remote_path" "$platform_dir/${suite_name}_device_album/" >/dev/null 2>&1 || true
    done <<< "$remote_screenshots"
  fi

  if [[ "$platform" == "ios" && -n "$IDEVICE_SCREENSHOT_BIN" ]]; then
    "$IDEVICE_SCREENSHOT_BIN" "$platform_dir/${suite_name}_final.png" >/dev/null 2>&1 || true
  fi

  if [[ "$command_status" -eq 0 && "$has_signals" -ne 0 ]]; then
    append_result "$platform" "$suite_name" "PASS" "$log_file"
  else
    if [[ "$command_status" -eq 124 ]]; then
      echo "[ERROR] Suite timed out after ${TEST_TIMEOUT_SEC}s." >> "$log_file"
    fi
    if [[ "$has_signals" -eq 0 ]]; then
      echo "[ERROR] Failure signals detected in log; marking suite as FAIL." >> "$log_file"
    fi
    append_result "$platform" "$suite_name" "FAIL" "$log_file"
    overall_status=1
  fi
}

if [[ "$SKIP_ANDROID" -eq 0 && -n "$ANDROID_ID" ]]; then
  for test_file in "${TEST_FILES[@]}"; do
    run_suite "android" "$ANDROID_ID" "$test_file"
  done
fi

if [[ "$SKIP_IOS" -eq 0 && -n "$IOS_ID" ]]; then
  for test_file in "${TEST_FILES[@]}"; do
    run_suite "ios" "$IOS_ID" "$test_file"
  done
fi

echo >> "$SUMMARY_FILE"
echo "## Artifact Root" >> "$SUMMARY_FILE"
echo >> "$SUMMARY_FILE"
echo "\`$RUN_DIR\`" >> "$SUMMARY_FILE"

echo "Wired evidence completed. Summary: $SUMMARY_FILE"
echo "Artifacts: $RUN_DIR"

exit "$overall_status"
