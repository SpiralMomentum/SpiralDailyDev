#!/usr/bin/env bash
# APK size guard — compares built APK against baseline
# Usage: check_app_size.sh <app_name> <apk_path> [baseline_file]
#
# Exit codes:
#   0 — within budget
#   1 — exceeds baseline by more than 2MB

set -euo pipefail

APP_NAME="${1:?Usage: check_app_size.sh <app_name> <apk_path> [baseline_file]}"
APK_PATH="${2:?Usage: check_app_size.sh <app_name> <apk_path> [baseline_file]}"
BASELINE_FILE="${3:-.ci/size-baseline.json}"

APK_SIZE_MB=$(du -m "$APK_PATH" | cut -f1)
echo "APK size for $APP_NAME: ${APK_SIZE_MB}MB"

if [ ! -f "$BASELINE_FILE" ]; then
  echo "No baseline file found at $BASELINE_FILE — reporting only"
  echo "### $APP_NAME APK Size: ${APK_SIZE_MB}MB (no baseline)" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
  exit 0
fi

# jq is available on GitHub Actions runners
BASELINE_MB=$(jq -r --arg app "$APP_NAME" '.[$app] // empty' "$BASELINE_FILE")

if [ -z "$BASELINE_MB" ]; then
  echo "No baseline for $APP_NAME — reporting only"
  echo "### $APP_NAME APK Size: ${APK_SIZE_MB}MB (no baseline entry)" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
  exit 0
fi

DIFF=$((APK_SIZE_MB - BASELINE_MB))
echo "Baseline: ${BASELINE_MB}MB | Current: ${APK_SIZE_MB}MB | Delta: ${DIFF}MB"
echo "### $APP_NAME APK Size: ${APK_SIZE_MB}MB (baseline: ${BASELINE_MB}MB, delta: ${DIFF}MB)" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"

THRESHOLD=2
if [ "$DIFF" -gt "$THRESHOLD" ]; then
  echo "::error::APK size increased by ${DIFF}MB (threshold: ${THRESHOLD}MB)"
  exit 1
fi

echo "APK size within budget"
