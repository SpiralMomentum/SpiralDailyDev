#!/usr/bin/env python3
"""
chrome_extension 백엔드 엔트리포인트.

동작 방식:
1. 포트 7892에 로컬 HTTP 서버 시작
2. AppleScript로 Chrome을 Play Console 페이지로 이동
3. content.js가 GET /cmd 로 명령을 가져가서 실행하고 POST /result 로 결과 전달
4. 결과를 stdout JSON으로 출력하고 종료
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from socketserver import ThreadingMixIn


class ThreadingHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True


PORT = 7892
TIMEOUT = 30  # content.js 응답 대기 기본 최대 초
# 여러 화면을 거치는 단계는 더 오래 걸린다 (콘텐츠 등급 실측 약 20초)
STEP_TIMEOUT = {'set_store_settings': 60, 'set_content_rating': 90, 'set_target_audience': 60}
CREATE_WAIT = 600  # 사용자가 법적 동의 후 "앱 만들기"를 누를 때까지 대기 최대 초
CREATE_WAIT_ACCEPTED = 60  # --accept-terms로 content.js가 직접 누른 뒤 앱 페이지로 이동할 때까지
CREATED_APP_URL = re.compile(r'/developers/\d+/app/(\d+)/')


def created_app_id(url: str) -> str | None:
    m = CREATED_APP_URL.search(url)
    return m.group(1) if m else None


def step_timeout(step: str) -> int:
    return STEP_TIMEOUT.get(step, TIMEOUT)


def create_wait(accept_terms: bool) -> int:
    return CREATE_WAIT_ACCEPTED if accept_terms else CREATE_WAIT


def wait_for_created_app(limit: int, accept_terms: bool = False) -> dict:
    """앱 생성 후 이동하는 /app/<id>/ URL에서 app_id를 얻는다.
    법적 동의는 --accept-terms가 없으면 사용자가 직접 체크하고 "앱 만들기"를 누른다."""
    import time
    if not accept_terms:
        print(f'[chrome_extension] Chrome에서 법적 동의 체크 후 "앱 만들기"를 눌러주세요 (최대 {limit}초 대기)',
              file=sys.stderr, flush=True)
    deadline = time.time() + limit
    while time.time() < deadline:
        app_id = created_app_id(get_chrome_url())
        if app_id:
            return {'success': True, 'app_id': app_id, 'message': f'앱 생성됨: {app_id}'}
        time.sleep(2)
    return {'success': False, 'app_id': None, 'message': f'앱 생성 대기 시간 초과 ({limit}s)'}

STEP_PATHS = {
    'create_app':         '',  # /create-new-app 은 app_id 없이
    'set_store_settings': '/app/{app_id}/store-settings',
    'set_privacy_policy': '/app/{app_id}/app-content/privacy-policy',
    'set_ads':            '/app/{app_id}/app-content/ads-declaration',
    'set_app_access':     '/app/{app_id}/app-content/testing-credentials',
    'set_content_rating': '/app/{app_id}/app-content/content-rating-overview',
    'set_target_audience':'/app/{app_id}/app-content/target-audience-content',
}


def parse_args() -> dict:
    args = sys.argv[1:]
    result: dict = {}
    i = 0
    while i < len(args):
        if args[i].startswith('--') and i + 1 < len(args):
            key = args[i][2:].replace('-', '_')
            result[key] = args[i + 1]
            i += 2
        else:
            i += 1
    return result


def _do_navigate(url: str) -> None:
    # 단순하게 현재 활성 탭을 직접 이동
    script = f'tell application "Google Chrome" to set URL of active tab of front window to "{url}"'
    r = subprocess.run(['osascript', '-e', script], capture_output=True, text=True)
    if r.returncode != 0:
        print(f'[chrome_extension] AppleScript 오류: {r.stderr.strip()}', file=sys.stderr)
        # fallback: open location
        subprocess.run(['osascript', '-e', f'tell application "Google Chrome" to open location "{url}"'],
                       capture_output=True)


def get_chrome_url() -> str:
    r = subprocess.run(
        ['osascript', '-e', 'tell application "Google Chrome" to return URL of active tab of front window'],
        capture_output=True, text=True
    )
    return r.stdout.strip()


def navigate_chrome(url: str, expected_path: str = '') -> None:
    import time
    # 최대 4회 시도: Play Console의 SPA 자체 라우팅이 navigate를 덮어쓸 수 있음
    for attempt in range(4):
        _do_navigate(url)
        time.sleep(2)
        actual = get_chrome_url()
        check = expected_path or url
        if check in actual:
            return
        # 맞지 않으면 잠시 대기 후 재시도
        time.sleep(2)


class Handler(BaseHTTPRequestHandler):
    cmd: dict | None = None
    result: dict | None = None
    result_event = threading.Event()

    def log_message(self, *_):
        pass  # 로그 억제

    def do_GET(self):
        if self.path == '/cmd':
            body = json.dumps(self.server.cmd or {}).encode()
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        if self.path == '/result':
            length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(length)
            self.server.result = json.loads(body)
            self.server.result_event.set()
            self.send_response(200)
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
        else:
            self.send_response(404)
            self.end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()


def main() -> None:
    args = parse_args()
    step        = args.get('step')
    config      = json.loads(args.get('config', '{}'))
    app_id      = args.get('app_id')
    developer_id = args.get('developer_id')

    # 단계별 정확한 URL로 이동 (content.js가 navigate하면 컨텍스트 파괴됨)
    base = f'https://play.google.com/console/u/0/developers/{developer_id}'
    if step == 'create_app':
        url = f'{base}/create-new-app'
    else:
        path = STEP_PATHS.get(step, '')
        url = base + path.format(app_id=app_id or '')
    # expected_path: URL에서 확인할 경로 부분
    if step == 'create_app':
        expected_path = 'create-new-app'
    else:
        expected_path = STEP_PATHS.get(step, '').format(app_id=app_id or '').lstrip('/')

    navigate_chrome(url, expected_path)

    actual_url = get_chrome_url()
    print(f'[chrome_extension] 목표: {url}', file=sys.stderr)
    print(f'[chrome_extension] 실제: {actual_url}', file=sys.stderr)

    # 추가 대기 (SPA 렌더링 완료 보장)
    import time
    time.sleep(1)

    # HTTP 서버 초기화 (이동 완료 후 명령 서빙 시작)
    httpd = ThreadingHTTPServer(('localhost', PORT), Handler)
    httpd.cmd = {'step': step, 'config': config, 'app_id': app_id, 'developer_id': developer_id}
    httpd.result = None
    httpd.result_event = threading.Event()
    Handler.server = httpd  # 핸들러가 서버 상태 접근용

    # 서버를 백그라운드 스레드에서 실행
    t = threading.Thread(target=httpd.serve_forever, daemon=True)
    t.start()
    print(f'[chrome_extension] {step} 대기 중...', file=sys.stderr)

    # 결과 대기 - "페이지 불일치"는 무시하고 올바른 결과가 올 때까지 대기
    import time as _time
    timeout = step_timeout(step)
    deadline = _time.time() + timeout
    result = None
    while _time.time() < deadline:
        remaining = deadline - _time.time()
        if httpd.result_event.wait(timeout=min(remaining, 2.0)):
            r = httpd.result
            if r.get('success') or '페이지 불일치' not in r.get('message', ''):
                result = r
                break
            # 페이지 불일치 → 아직 이동 중, 계속 대기
            httpd.result = None
            httpd.result_event.clear()
    if result is None:
        result = {'success': False, 'app_id': None, 'message': f'timeout ({timeout}s)'}

    httpd.shutdown()

    if step == 'create_app' and result.get('success') and not result.get('app_id'):
        accepted = bool(config.get('_accept_terms'))
        result = wait_for_created_app(create_wait(accepted), accepted)
    print(f'[chrome_extension] 결과: {result}', file=sys.stderr)
    print(json.dumps(result, ensure_ascii=False))
    sys.exit(0 if result.get('success') else 1)


if __name__ == '__main__':
    main()
