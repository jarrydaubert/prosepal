#!/bin/bash

set -euo pipefail

echo "Running critical smoke suite..."

flutter test \
  test/app/app_lifecycle_test.dart \
  test/config/app_config_test.dart \
  test/widgets/screens/home_screen_test.dart \
  test/widgets/screens/generate_screen_test.dart \
  test/widgets/screens/results_screen_test.dart \
  test/widgets/screens/settings_screen_test.dart

echo "Critical smoke suite passed."
