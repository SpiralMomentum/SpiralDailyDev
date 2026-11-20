"""Graph 계열 API(Instagram, Threads) 공통 HTTP 호출 함수 (표준 라이브러리만 사용).

- 순수 함수(build_request, parse_error, backoff)와 부수효과 함수(send, call)를 분리한다.
- 토큰은 로그/예외 메시지에 절대 포함하지 않는다.
- 일시적 오류(5xx, code 1/2/4/17/32/613, is_transient)는 지수 백오프로 재시도한다.
"""
from __future__ import annotations

import json
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from typing import Any, Callable, Mapping

TRANSIENT_CODES = frozenset({1, 2, 4, 17, 32, 613})
Json = Mapping[str, Any]


class ApiError(RuntimeError):
    """API 오류. 생성 후 변경하지 않는 값 객체로 사용한다."""

    def __init__(self, status: int, payload: Json):
        err = payload.get("error", {}) if isinstance(payload, Mapping) else {}
        self.status = status
        self.code = err.get("code")
        self.subcode = err.get("error_subcode")
        self.transient = bool(err.get("is_transient")) or self.code in TRANSIENT_CODES or status >= 500
        self.fbtrace_id = err.get("fbtrace_id")
        user_msg = err.get("error_user_msg") or err.get("error_user_title")
        parts = [f"HTTP {status} code={self.code} subcode={self.subcode} {err.get('message') or str(payload)[:300]}",
                 user_msg and f"| {user_msg}", self.fbtrace_id and f"| fbtrace_id={self.fbtrace_id}"]
        super().__init__(" ".join(p for p in parts if p))


def logger(prefix: str) -> Callable[[str], None]:
    return lambda msg: print(f"[{prefix}] {msg}", file=sys.stderr, flush=True)


log = logger("mkt")


# ---------------------------------------------------------------- 순수 함수

def compact(params: Mapping[str, Any]) -> dict[str, Any]:
    return {k: v for k, v in params.items() if v is not None}


def build_request(base: str, token: str, method: str, path: str, params: Mapping[str, Any]) -> urllib.request.Request:
    """token이 빈 문자열이면 access_token을 붙이지 않는다 (OAuth 코드 교환 등)."""
    query = urllib.parse.urlencode({**compact(params), **({"access_token": token} if token else {})})
    url = f"{base.rstrip('/')}/{path.lstrip('/')}"
    return (urllib.request.Request(f"{url}?{query}", method=method) if method == "GET"
            else urllib.request.Request(url, data=query.encode(), method=method))


def parse_error(status: int, raw: str) -> ApiError:
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError:
        payload = {"error": {"message": raw[:300]}}
    return ApiError(status, payload)


def backoff(attempt: int) -> float:
    return float(2 ** attempt)


# ---------------------------------------------------------------- 부수효과

def send(req: urllib.request.Request, timeout: float = 60.0) -> dict[str, Any]:
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.loads(resp.read().decode() or "{}")
    except urllib.error.HTTPError as e:
        raise parse_error(e.code, e.read().decode(errors="replace")) from None
    except (urllib.error.URLError, TimeoutError) as e:
        raise ApiError(599, {"error": {"message": f"network: {e}", "is_transient": True}}) from None


def with_retry(fn: Callable[[], dict[str, Any]], label: str, retries: int = 3,
               sleep: Callable[[float], None] = time.sleep) -> dict[str, Any]:
    def attempt(n: int) -> dict[str, Any]:
        try:
            return fn()
        except ApiError as e:
            if not e.transient or n > retries:
                raise
            log(f"{label} 일시 오류, {backoff(n):.0f}s 후 재시도 ({n}/{retries}): {e}")
            sleep(backoff(n))
            return attempt(n + 1)
    return attempt(1)


def call(base: str, token: str, method: str, path: str, **params: Any) -> dict[str, Any]:
    return with_retry(lambda: send(build_request(base, token, method, path, params)), f"{method} {path}")
