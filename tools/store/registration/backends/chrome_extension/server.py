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
import subprocess
import sys
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from socketserver import ThreadingMixIn


class ThreadingHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True


PORT = 7892
TIMEOUT = 30  # content.js 응답 대기 최대 초

STEP_PATHS = {
    'create_app':         '',  # /create-new-app 은 app_id 없이
    'set_store_settings': '/app/{app_id}/store-settings',
    'set_privacy_policy': '/app/{app_id}/app-content/privacy-policy',
    'set_ads':            '/app/{app_id}/app-content/ads',
    'set_app_access':     '/app/{app_id}/app-content/app-access',
    'set_content_rating': '/app/{app_id}/app-content/ratings',
    'set_target_audience':'/app/{app_id}/app-content/target-audience-and-content',
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
    deadline = _time.time() + TIMEOUT
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
        result = {'success': False, 'app_id': None, 'message': f'timeout ({TIMEOUT}s)'}

    httpd.shutdown()
    print(f'[chrome_extension] 결과: {result}', file=sys.stderr)
    print(json.dumps(result, ensure_ascii=False))
    sys.exit(0 if result.get('success') else 1)


if __name__ == '__main__':
    main()
