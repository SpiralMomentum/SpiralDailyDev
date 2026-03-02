#!/usr/bin/env bash
# APK size baseline comparison script
# Usage: check_app_size.sh <app_name> <apk_path> [baseline_file]
set -euo pipefail

APP_NAME="${1:?Usage: check_app_size.sh <app_name> <apk_path> [baseline_file]}"
APK_PATH="${2:?Usage: check_app_size.sh <app_name> <apk_path> [baseline_file]}"
BASELINE_FILE="${3:-.ci/size-baseline.json}"
MAX_INCREASE_MB=2

if [ ! -f "$APK_PATH" ]; then
  echo "::error::APK not found: $APK_PATH"
  exit 1
fi

APK_SIZE_MB=$(du -m "$APK_PATH" | cut -f1)
echo "APK size for $APP_NAME: ${APK_SIZE_MB}MB"

if [ ! -f "$BASELINE_FILE" ]; then
  echo "No baseline file found at $BASELINE_FILE — skipping comparison"
  echo "### $APP_NAME APK Size: ${APK_SIZE_MB}MB (no baseline)" >> "$GITHUB_STEP_SUMMARY"
  exit 0
fi

BASELINE_MB=$(python3 -c "
import json, sys
with open('$BASELINE_FILE') as f:
    data = json.load(f)
print(data.get('$APP_NAME', 0))
" 2>/dev/null || echo 0)

if [ "$BASELINE_MB" -eq 0 ]; then
  echo "No baseline for $APP_NAME — skipping comparison"
  echo "### $APP_NAME APK Size: ${APK_SIZE_MB}MB (no baseline)" >> "$GITHUB_STEP_SUMMARY"
  exit 0
fi

DIFF=$((APK_SIZE_MB - BASELINE_MB))
echo "Baseline: ${BASELINE_MB}MB, Current: ${APK_SIZE_MB}MB, Diff: ${DIFF}MB"
echo "### $APP_NAME APK Size: ${APK_SIZE_MB}MB (baseline: ${BASELINE_MB}MB, diff: ${DIFF}MB)" >> "$GITHUB_STEP_SUMMARY"

if [ "$DIFF" -gt "$MAX_INCREASE_MB" ]; then
  echo "::error::APK size increased by ${DIFF}MB (max allowed: ${MAX_INCREASE_MB}MB)"
  exit 1
fi

echo "APK size within acceptable range"
