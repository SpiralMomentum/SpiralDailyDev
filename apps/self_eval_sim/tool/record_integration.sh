#!/usr/bin/env bash
# 통합 테스트를 Android 기기/에뮬레이터에서 돌리면서 화면을 녹화한다.
# 산출물: build/integration_video/
#   self_eval_flow_partNN.mp4  (screenrecord 한도 180초 단위로 이어서 녹화, 구간 사이 1초 미만 공백)
#   frames/*.png               (3초 간격 스크린샷)
#   drive.log
# 사용:
#   DEVICE=emulator-5554 tool/record_integration.sh
#   MODEL_URL=http://10.0.2.2:8765/gemma-4-E2B-it.litertlm tool/record_integration.sh   # 로컬 모델 미러
#   BITRATE=4000000 tool/record_integration.sh                                          # 파일 크기 줄이기
set -euo pipefail
cd "$(dirname "$0")/.."

DEVICE=${DEVICE:-emulator-5554}
OUT=${OUT:-build/integration_video}
BITRATE=${BITRATE:-4000000}
TARGET=${TARGET:-integration_test/app_flow_test.dart}
APP=com.spiralmomentum.self_eval_sim
DEFINES=()
[ -n "${MODEL_URL:-}" ] && DEFINES+=(--dart-define=MODEL_URL="$MODEL_URL")

rm -rf "$OUT" && mkdir -p "$OUT/frames"
adb -s "$DEVICE" shell am force-stop "$APP" || true
adb -s "$DEVICE" shell 'rm -f /sdcard/self_eval_flow_part*.mp4'

wait_app() { until adb -s "$DEVICE" shell pidof "$APP" >/dev/null 2>&1; do sleep 0.2; done; }
alive() { adb -s "$DEVICE" shell pidof "$APP" >/dev/null 2>&1; }

# 앱 프로세스가 뜨는 순간부터, 앱이 살아 있는 동안 180초 구간으로 이어서 녹화한다.
(
  wait_app
  n=1
  while alive; do
    adb -s "$DEVICE" shell screenrecord --time-limit 180 --bit-rate "$BITRATE" \
      "/sdcard/self_eval_flow_part$(printf '%02d' $n).mp4" || true
    n=$((n + 1))
  done
) &
REC=$!

(
  wait_app
  i=0
  while alive; do
    adb -s "$DEVICE" exec-out screencap -p > "$OUT/frames/$(printf '%03d' $i).png" || true
    i=$((i + 1))
    sleep 3
  done
) &
SHOTS=$!

set +e
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target="$TARGET" \
  ${DEFINES[@]+"${DEFINES[@]}"} \
  -d "$DEVICE" 2>&1 | tee "$OUT/drive.log"
STATUS=${PIPESTATUS[0]}
set -e

sleep 2
adb -s "$DEVICE" shell am force-stop "$APP" || true
adb -s "$DEVICE" shell 'kill -2 $(pidof screenrecord)' 2>/dev/null || true
sleep 2
kill "$REC" "$SHOTS" 2>/dev/null || true
for f in $(adb -s "$DEVICE" shell 'ls /sdcard/self_eval_flow_part*.mp4' | tr -d '\r'); do
  adb -s "$DEVICE" pull "$f" "$OUT/" >/dev/null
done
ls -l "$OUT"/*.mp4
echo "drive exit $STATUS"
exit "$STATUS"
