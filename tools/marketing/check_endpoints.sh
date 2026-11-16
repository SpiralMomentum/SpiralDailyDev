#!/bin/bash
# 플랫폼 게시 API 엔드포인트 생존 확인 (무인증 호출).
# 401/400/403 = 엔드포인트 존재(인증 필요), 404/410/301 = 폐지·이동 의심.
set -u
LIST="$(dirname "$0")/endpoints.txt"
TMP="$(mktemp)"
while IFS='|' read -r name method url; do
  [ -z "$name" ] && continue
  code=$(curl -s -o "$TMP" -w '%{http_code}' -m 15 -X "$method" -H 'Content-Type: application/json' -d '{}' "$url")
  printf '%-28s %s  %s\n' "$name" "$code" "$(head -c 90 "$TMP" | tr '\n' ' ')"
done < "$LIST"
rm -f "$TMP"
