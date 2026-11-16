#!/usr/bin/env bash
# Claude in Chrome 백엔드 CLI.
# 계약: tools/store/registration/contract.json
#
# 의존성: claude CLI 설치 + 로그인, Chrome에 Claude in Chrome 익스텐션 설치
#
# 출력: stdout에 JSON 한 줄
# 로그: stderr

set -euo pipefail

STEP=""
CONFIG="{}"
APP_ID=""
DEVELOPER_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --step)        STEP="$2";        shift 2 ;;
    --config)      CONFIG="$2";      shift 2 ;;
    --app-id)      APP_ID="$2";      shift 2 ;;
    --developer-id) DEVELOPER_ID="$2"; shift 2 ;;
    *) shift ;;
  esac
done

log() { echo "[claude_chrome] $*" >&2; }

run_claude() {
  claude -p "$1" --output-format text 2>/dev/null
}

CONSOLE_URL="https://play.google.com/console/u/0/developers/${DEVELOPER_ID}"

case "$STEP" in

  create_app)
    NAME_EN=$(echo "$CONFIG" | python3 -c "import json,sys; print(json.load(sys.stdin)['name_en'])")
    PKG=$(echo "$CONFIG"    | python3 -c "import json,sys; print(json.load(sys.stdin)['package_name'])")
    log "앱 생성: $NAME_EN ($PKG)"
    PROMPT="Open ${CONSOLE_URL}/create-new-app in Chrome.
Fill: app name='${NAME_EN}', package='${PKG}'.
Select app type and pricing from config.
Wait for user to check legal checkboxes, then submit.
After redirect to app-dashboard, extract APP_ID from URL.
Return only: {\"success\":true,\"app_id\":\"<id>\",\"message\":\"\"}"
    RESULT=$(run_claude "$PROMPT")
    echo "$RESULT"
    ;;

  set_store_settings)
    CATEGORY=$(echo "$CONFIG" | python3 -c "import json,sys; print(json.load(sys.stdin)['category'])")
    log "스토어 설정: category=$CATEGORY"
    PROMPT="On Chrome tab at ${CONSOLE_URL}/app/${APP_ID}/store-settings:
Select category '${CATEGORY}', save.
Return only: {\"success\":true,\"app_id\":null,\"message\":\"\"}"
    RESULT=$(run_claude "$PROMPT")
    echo "$RESULT"
    ;;

  set_privacy_policy)
    URL=$(echo "$CONFIG" | python3 -c "import json,sys; print(json.load(sys.stdin)['privacy_policy_url'])")
    log "개인정보처리방침: $URL"
    PROMPT="On Chrome tab at ${CONSOLE_URL}/app/${APP_ID}/app-content/privacy-policy:
Enter URL '${URL}', save.
Return only: {\"success\":true,\"app_id\":null,\"message\":\"\"}"
    RESULT=$(run_claude "$PROMPT")
    echo "$RESULT"
    ;;

  set_ads)
    ADS=$(echo "$CONFIG" | python3 -c "import json,sys; print(json.load(sys.stdin)['ads'])")
    log "광고 여부: $ADS"
    PROMPT="On Chrome tab at ${CONSOLE_URL}/app/${APP_ID}/app-content/ads:
Select ads=${ADS} radio button using JS: document.querySelectorAll('input[role=\"radio\"]')[$([ "$ADS" = "True" ] && echo 1 || echo 0)].click()
Then click submit.
Return only: {\"success\":true,\"app_id\":null,\"message\":\"\"}"
    RESULT=$(run_claude "$PROMPT")
    echo "$RESULT"
    ;;

  set_app_access)
    LOGIN=$(echo "$CONFIG" | python3 -c "import json,sys; print(json.load(sys.stdin)['requires_login'])")
    log "앱 액세스: requires_login=$LOGIN"
    PROMPT="On Chrome tab at ${CONSOLE_URL}/app/${APP_ID}/app-content/app-access:
Select requires_login=${LOGIN} radio (index $([ "$LOGIN" = "True" ] && echo 1 || echo 0)) via JS click, then submit.
Return only: {\"success\":true,\"app_id\":null,\"message\":\"\"}"
    RESULT=$(run_claude "$PROMPT")
    echo "$RESULT"
    ;;

  set_content_rating)
    log "콘텐츠 등급 설문"
    PROMPT="On Chrome tab at ${CONSOLE_URL}/app/${APP_ID}/app-content/ratings:
Click start questionnaire, answer all questions with 'none/no' (first radio in each group), calculate, save.
Return only: {\"success\":true,\"app_id\":null,\"message\":\"\"}"
    RESULT=$(run_claude "$PROMPT")
    echo "$RESULT"
    ;;

  set_target_audience)
    AGE=$(echo "$CONFIG" | python3 -c "import json,sys; print(json.load(sys.stdin)['target_age'])")
    IDX=$(python3 -c "print({'all':0,'teen':1,'adult':2}.get('${AGE}',0))")
    log "타겟층: $AGE (index=$IDX)"
    PROMPT="On Chrome tab at ${CONSOLE_URL}/app/${APP_ID}/app-content/target-audience-and-content:
Select age group index ${IDX} via JS: document.querySelectorAll('input[role=\"radio\"]')[${IDX}].click()
Then submit.
Return only: {\"success\":true,\"app_id\":null,\"message\":\"\"}"
    RESULT=$(run_claude "$PROMPT")
    echo "$RESULT"
    ;;

  *)
    echo "{\"success\":false,\"app_id\":null,\"message\":\"unknown step: ${STEP}\"}"
    exit 1
    ;;
esac
