#!/usr/bin/env bash
# Native Messaging host 등록 스크립트.
# Chrome Extension 로드 후 Extension ID를 인자로 전달한다.
#
# Usage: bash install.sh <EXTENSION_ID>
#   예)  bash install.sh abcdefghijklmnopabcdefghijklmnop

set -euo pipefail

EXTENSION_ID="${1:?Usage: bash install.sh <EXTENSION_ID>}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_PY="$SCRIPT_DIR/host.py"
MANIFEST_SRC="$SCRIPT_DIR/com.spiraldev.registration.json"
MANIFEST_DST="$SCRIPT_DIR/com.spiraldev.registration.installed.json"
CHROME_NM_DIR="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts"

# host.py 실행권한
chmod +x "$HOST_PY"

# manifest에 실제 경로와 Extension ID 주입
sed \
  -e "s|__HOST_PATH__|$HOST_PY|g" \
  -e "s|__EXTENSION_ID__|$EXTENSION_ID|g" \
  "$MANIFEST_SRC" > "$MANIFEST_DST"

# Chrome NativeMessagingHosts 디렉토리에 등록
mkdir -p "$CHROME_NM_DIR"
cp "$MANIFEST_DST" "$CHROME_NM_DIR/com.spiraldev.registration.json"

echo "설치 완료."
echo "  host:      $HOST_PY"
echo "  extension: $EXTENSION_ID"
echo "  manifest:  $CHROME_NM_DIR/com.spiraldev.registration.json"
echo ""
echo "Chrome을 재시작하면 적용됩니다."
