#!/bin/bash

set -euo pipefail

FULL_RUNS="${FULL_RUNS:-8}"
SERIAL_RUNS="${SERIAL_RUNS:-2}"
TARGET_RUNS="${TARGET_RUNS:-10}"
LOG_DIR="${LOG_DIR:-/tmp/prosepal-flake-audit}"

TARGET_FILES=(
  "test/widgets/screens/email_auth_screen_test.dart"
  "test/widgets/screens/settings_screen_test.dart"
  "test/widgets/screens/generate_screen_test.dart"
  "test/widgets/screens/history_screen_test.dart"
)

mkdir -p "$LOG_DIR"

run_test() {
  local label="$1"
  shift
  local log_file="$LOG_DIR/${label}.log"

  if "$@" >"$log_file" 2>&1; then
    echo "[PASS] $label"
  else
    echo "[FAIL] $label (log: $log_file)"
    tail -n 120 "$log_file" || true
    exit 1
  fi
}

echo "Starting flaky test audit..."
echo "FULL_RUNS=$FULL_RUNS SERIAL_RUNS=$SERIAL_RUNS TARGET_RUNS=$TARGET_RUNS"
echo "Logs: $LOG_DIR"

for i in $(seq 1 "$FULL_RUNS"); do
  seed=$((100000 + i * 7919))
  label="full_random_${i}_seed_${seed}"
  echo "[RUN] $label"
  run_test "$label" flutter test --test-randomize-ordering-seed="$seed"
done

for i in $(seq 1 "$SERIAL_RUNS"); do
  seed=$((300000 + i * 4441))
  label="full_serial_${i}_seed_${seed}"
  echo "[RUN] $label"
  run_test \
    "$label" \
    flutter test --concurrency=1 --test-randomize-ordering-seed="$seed"
done

for file in "${TARGET_FILES[@]}"; do
  short_name="$(basename "$file" .dart)"
  for i in $(seq 1 "$TARGET_RUNS"); do
    seed=$((200000 + i * 1297))
    label="target_${short_name}_${i}_seed_${seed}"
    echo "[RUN] $label"
    run_test "$label" flutter test "$file" --test-randomize-ordering-seed="$seed"
  done
done

echo "Flaky test audit complete: all runs passed."
