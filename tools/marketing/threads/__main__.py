"""Threads 게시 CLI.

실행: python tools/marketing/threads <command> [...]
모든 명령은 결과를 stdout에 JSON 한 줄로 출력하고, 진행 로그는 stderr로 보낸다.
종료 코드: 0 성공/건너뜀, 1 API·네트워크 오류, 2 입력 검증 실패, 3 게시 한도 초과

명령 (API 단계별):
  check                       계정 정보 + 24시간 게시 한도
  limit                       24시간 게시 한도 (게시 250, 답글 1000)
  upload <파일>               로컬 파일 -> 공개 URL (MKT_THREADS_MEDIA_HOST)
  create-text <text> [--link url] [--topic 태그]
  create-image <url> [--text ..] [--carousel-item]
  create-video <url> [--text ..] [--carousel-item]
  create-carousel <child_id,...> [--text ..]
  status <container_id>       컨테이너 상태 (IN_PROGRESS/FINISHED/PUBLISHED/ERROR/EXPIRED)
  wait <container_id>         FINISHED 될 때까지 대기
  publish <container_id>      컨테이너 게시
  info <media_id>             게시물 정보 (permalink 등)
  list [--limit N]            최근 게시물
  delete <media_id>           게시물 삭제 (threads_delete 권한) + 원장에 삭제 기록
  refresh-token               장기 토큰 60일 연장 (.env 갱신)
  token-scopes                현재 토큰의 권한 목록과 만료 시각
  auth-url                    삭제 권한 포함 인증 URL 출력 (MKT_THREADS_APP_ID, MKT_THREADS_REDIRECT_URI 필요)
  exchange-code <code|URL>    리디렉션된 URL(또는 code)로 60일 토큰 발급 후 .env 저장 (MKT_THREADS_APP_SECRET 필요)

명령 (파이프라인):
  validate <job.yaml>         job 검증만 (API 호출 없음)
  post <job.yaml> [--dry-run] [--force]
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any, Callable, Mapping

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))  # tools/marketing

from common import hosting  # noqa: E402
from common.http_api import ApiError  # noqa: E402
from threads import publisher as pub  # noqa: E402
from threads.config import Config, load_config  # noqa: E402

Args = argparse.Namespace
Result = tuple  # (stdout JSON 객체, 종료 코드)
Handler = Callable[[Config, Args], Result]

STATUS_EXIT: Mapping[str, int] = {"invalid": 2, "quota_exceeded": 3}
FLAG = {"action": "store_true"}

ARG_SPECS: Mapping[str, tuple] = {
    "check": (),
    "limit": (),
    "upload": (("file",),),
    "create-text": (("text",), ("--link",), ("--topic",)),
    "create-image": (("url",), ("--text",), ("--carousel-item", FLAG)),
    "create-video": (("url",), ("--text",), ("--carousel-item", FLAG)),
    "create-carousel": (("children",), ("--text",)),
    "status": (("container_id",),),
    "wait": (("container_id",), ("--timeout", {"type": float, "default": 300})),
    "publish": (("container_id",),),
    "info": (("media_id",),),
    "list": (("--limit", {"type": int, "default": 10}),),
    "delete": (("media_id",),),
    "refresh-token": (),
    "token-scopes": (),
    "auth-url": (),
    "exchange-code": (("code",),),
    "validate": (("job",),),
    "post": (("job",), ("--dry-run", FLAG), ("--force", FLAG)),
}


def build_parser(specs: Mapping[str, tuple]) -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="threads", description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    for name, args in specs.items():
        sp = sub.add_parser(name)
        for spec in args:
            sp.add_argument(spec[0], **(spec[1] if len(spec) > 1 else {}))
    return p


def require(value: str, key: str) -> str:
    if not value:
        raise RuntimeError(f"{key} 미설정 (tools/marketing/.env)")
    return value


def ok(obj: Any) -> Result:
    return obj, 0


def post_result(r: Mapping[str, Any]) -> Result:
    return r, STATUS_EXIT.get(r["status"], 0)


HANDLERS: Mapping[str, Handler] = {
    "check": lambda cfg, a: ok({"profile": pub.profile(cfg), "limit": pub.publishing_limit(cfg),
                                "api": cfg.api_base, "media_host": cfg.host_provider}),
    "limit": lambda cfg, a: ok(pub.publishing_limit(cfg)),
    "upload": lambda cfg, a: ok({"url": hosting.to_public_url(a.file, cfg.host_provider)}),
    "create-text": lambda cfg, a: ok({"id": pub.create_container(cfg, pub.text_params(a.text, a.link, a.topic))}),
    "create-image": lambda cfg, a: ok({"id": pub.create_container(cfg, pub.image_params(a.url, a.text, a.carousel_item))}),
    "create-video": lambda cfg, a: ok({"id": pub.create_container(cfg, pub.video_params(a.url, a.text, a.carousel_item))}),
    "create-carousel": lambda cfg, a: ok({"id": pub.create_container(cfg, pub.carousel_params(a.children.split(","), a.text))}),
    "status": lambda cfg, a: ok(pub.container_status(cfg, a.container_id)),
    "wait": lambda cfg, a: ok({"id": pub.wait_ready(cfg, a.container_id, timeout=a.timeout), "status": "FINISHED"}),
    "publish": lambda cfg, a: ok({"media_id": pub.publish_container(cfg, a.container_id)}),
    "info": lambda cfg, a: ok(pub.media_info(cfg, a.media_id)),
    "list": lambda cfg, a: ok(pub.list_threads(cfg, a.limit)),
    "delete": lambda cfg, a: ok(pub.delete_and_record(cfg, a.media_id)),
    "refresh-token": lambda cfg, a: ok(pub.refresh_token(cfg)),
    "token-scopes": lambda cfg, a: ok(pub.token_scopes(cfg)),
    "auth-url": lambda cfg, a: ok({"url": pub.authorize_url(require(cfg.app_id, "MKT_THREADS_APP_ID"),
                                                            require(cfg.redirect_uri, "MKT_THREADS_REDIRECT_URI"))}),
    "exchange-code": lambda cfg, a: ok(pub.exchange_code(
        cfg, require(cfg.app_id, "MKT_THREADS_APP_ID"), require(cfg.app_secret, "MKT_THREADS_APP_SECRET"),
        require(cfg.redirect_uri, "MKT_THREADS_REDIRECT_URI"), a.code)),
    "post": lambda cfg, a: post_result(pub.post_job(cfg, pub.load_job(Path(a.job)), dry_run=a.dry_run, force=a.force)),
}


def validate_only(a: Args) -> Result:
    errs = pub.validate_job(pub.load_job(Path(a.job)))
    return {"ok": not errs, "errors": errs}, (0 if not errs else 2)


def error_result(e: Exception) -> Result:
    return ({"error": str(e), "code": e.code, "subcode": e.subcode} if isinstance(e, ApiError)
            else {"error": f"{type(e).__name__}: {e}"}), 1


def run(a: Args) -> Result:
    if a.cmd == "validate":
        return validate_only(a)
    try:
        return HANDLERS[a.cmd](load_config(), a)
    except (ApiError, RuntimeError, TimeoutError, OSError, KeyError) as e:
        return error_result(e)


def main(argv: list | None = None) -> int:
    result, code = run(build_parser(ARG_SPECS).parse_args(argv))
    print(json.dumps(result, ensure_ascii=False))
    return code


if __name__ == "__main__":
    sys.exit(main())
