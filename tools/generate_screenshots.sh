#!/bin/bash
set -euo pipefail

# iOS App Store 스크린샷 자동 생성 스크립트
# 사용법: ./tools/generate_screenshots.sh

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SIMULATOR_NAME="iPhone 15 Pro Max"
SIMULATOR_UDID="62C3C6B6-A66F-4D46-9690-5AC0DE309229"
WAIT_SECONDS=12

APPS=(adage_spark daily_memo film_archive luck_insight world_field_guide world_of_beast)
APP_PATHS=(apps/adage_spark apps/daily_memo apps/film_archive apps/luck_insight apps/world_field_guide apps/world_of_beast)

echo "=== iOS App Store 스크린샷 생성 ==="
echo "시뮬레이터: $SIMULATOR_NAME"
echo ""

# 1. 시뮬레이터 부팅
echo "[1/3] 시뮬레이터 부팅 중..."
xcrun simctl boot "$SIMULATOR_UDID" 2>/dev/null || echo "이미 부팅됨"
sleep 3

# 2. 각 앱 스크린샷 캡처
for i in "${!APPS[@]}"; do
  APP="${APPS[$i]}"
  APP_PATH="${APP_PATHS[$i]}"
  APP_DIR="$REPO_ROOT/$APP_PATH"

  echo ""
  echo "[2/3] [$((i+1))/${#APPS[@]}] $APP 스크린샷 캡처 중..."

  # 스크린샷 저장 디렉토리
  SCREENSHOT_DIR="$REPO_ROOT/fastlane/metadata/$APP/screenshots/ko"
  mkdir -p "$SCREENSHOT_DIR"

  # Flutter 빌드 및 실행
  cd "$APP_DIR"
  echo "  빌드 중..."
  flutter build ios --simulator --no-pub 2>/dev/null

  echo "  앱 실행 중..."
  flutter run -d "$SIMULATOR_UDID" --no-hot --machine 2>/dev/null &
  FLUTTER_PID=$!

  # 앱 로딩 대기
  echo "  ${WAIT_SECONDS}초 대기..."
  sleep "$WAIT_SECONDS"

  # 스크린샷 캡처
  SCREENSHOT_FILE="$SCREENSHOT_DIR/APP_IPHONE_67_0.png"
  xcrun simctl io "$SIMULATOR_UDID" screenshot "$SCREENSHOT_FILE"
  echo "  저장: $SCREENSHOT_FILE"

  # en-US에도 같은 스크린샷 복사
  EN_DIR="$REPO_ROOT/fastlane/metadata/$APP/screenshots/en-US"
  mkdir -p "$EN_DIR"
  cp "$SCREENSHOT_FILE" "$EN_DIR/APP_IPHONE_67_0.png"

  # 앱 종료
  kill "$FLUTTER_PID" 2>/dev/null || true
  wait "$FLUTTER_PID" 2>/dev/null || true

  # 앱 언인스톨
  BUNDLE_IDS=(
    "com.spiraldev.adageSpark"
    "com.spiraldailydev.dailyMemo"
    "com.spiraldev.filmArchive"
    "com.spiraldev.luckInsight"
    "com.spiraldev.worldFieldGuide"
    "com.spiraldev.worldOfBeast"
  )
  xcrun simctl uninstall "$SIMULATOR_UDID" "${BUNDLE_IDS[$i]}" 2>/dev/null || true
done

cd "$REPO_ROOT"

# 3. 완료
echo ""
echo "[3/3] 완료!"
echo ""
echo "생성된 스크린샷:"
find fastlane/metadata/*/screenshots -name "*.png" 2>/dev/null | sort
echo ""
echo "시뮬레이터를 종료하려면: xcrun simctl shutdown $SIMULATOR_UDID"
