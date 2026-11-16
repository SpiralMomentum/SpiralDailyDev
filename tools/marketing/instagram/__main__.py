"""Instagram 게시 CLI.

실행: python tools/marketing/instagram <command> [...]
모든 명령은 결과를 stdout에 JSON 한 줄로 출력하고, 진행 로그는 stderr로 보낸다.
종료 코드: 0 성공/건너뜀, 1 API·네트워크 오류, 2 입력 검증 실패, 3 게시 한도 초과

명령 (API 단계별):
  check                       계정 정보 + 24시간 게시 한도
  limit                       24시간 게시 한도
  upload <파일>               로컬 파일 -> 공개 URL (MKT_IG_MEDIA_HOST)
  create-image <url> [--caption ..] [--carousel-item]
  create-video <url> [--caption ..] [--reel] [--carousel-item] [--cover url] [--no-feed]
  create-carousel <child_id,...> [--caption ..]
  status <container_id>       컨테이너 상태 (IN_PROGRESS/FINISHED/PUBLISHED/ERROR/EXPIRED)
  wait <container_id>         FINISHED 될 때까지 대기
  publish <container_id>      컨테이너 게시
  info <media_id>             게시물 정보 (permalink 등)
  list [--limit N]            최근 게시물
  comments <media_id> on|off  댓글 허용 여부 변경 (게시 후 API로 바꿀 수 있는 유일한 항목, 캡션 수정 불가)
  delete <media_id>           게시물 삭제 (지원되지 않을 수 있음)

명령 (파이프라인):
  validate <job.yaml>         job 검증만 (API 호출 없음)
  post <job.yaml> [--dry-run] [--force]
                              검증 -> 업로드 -> 컨테이너 -> 대기 -> 게시 -> 원장 기록 (중복 key는 건너뜀)
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any, Callable, Mapping

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))  # tools/marketing

from common import hosting  # noqa: E402
from instagram import publisher as pub  # noqa: E402
from instagram.config import Config, load_config  # noqa: E402
from instagram.graph_api import GraphError  # noqa: E402

Args = argparse.Namespace
Result = tuple  # (stdout JSON 객체, 종료 코드)
Handler = Callable[[Config, Args], Result]

STATUS_EXIT: Mapping[str, int] = {"invalid": 2, "quota_exceeded": 3}

# ---------------------------------------------------------------- 인자 정의 (데이터)

ARG_SPECS: Mapping[str, tuple] = {
    "check": (),
    "limit": (),
    "upload": (("file",),),
    "create-image": (("url",), ("--caption",), ("--carousel-item", {"action": "store_true"})),
    "create-video": (("url",), ("--caption",), ("--reel", {"action": "store_true"}),
                     ("--carousel-item", {"action": "store_true"}), ("--cover",), ("--no-feed", {"action": "store_true"})),
    "create-carousel": (("children",), ("--caption",)),
    "status": (("container_id",),),
    "wait": (("container_id",), ("--timeout", {"type": float, "default": 300})),
    "publish": (("container_id",),),
    "info": (("media_id",),),
    "list": (("--limit", {"type": int, "default": 10}),),
    "comments": (("media_id",), ("state", {"choices": ["on", "off"]})),
    "delete": (("media_id",),),
    "validate": (("job",),),
    "post": (("job",), ("--dry-run", {"action": "store_true"}), ("--force", {"action": "store_true"})),
}


def build_parser(specs: Mapping[str, tuple]) -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="instagram", description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    for name, args in specs.items():
        sp = sub.add_parser(name)
        for spec in args:
            sp.add_argument(spec[0], **(spec[1] if len(spec) > 1 else {}))
    return p


# ---------------------------------------------------------------- 명령 핸들러 (cfg, args) -> (결과, 종료 코드)

def ok(obj: Any) -> Result:
    return obj, 0


def post_result(r: Mapping[str, Any]) -> Result:
    return r, STATUS_EXIT.get(r["status"], 0)


HANDLERS: Mapping[str, Handler] = {
    "check": lambda cfg, a: ok({"account": pub.account_info(cfg), "limit": pub.publishing_limit(cfg),
                                "graph": cfg.graph_base, "media_host": cfg.host_provider}),
    "limit": lambda cfg, a: ok(pub.publishing_limit(cfg)),
    "upload": lambda cfg, a: ok({"url": hosting.to_public_url(a.file, cfg.host_provider)}),
    "create-image": lambda cfg, a: ok({"id": pub.create_container(
        cfg, pub.image_params(a.url, a.caption, a.carousel_item))}),
    "create-video": lambda cfg, a: ok({"id": pub.create_container(cfg, pub.video_params(
        a.url, a.caption, reel=a.reel, carousel_item=a.carousel_item, cover_url=a.cover, share_to_feed=not a.no_feed))}),
    "create-carousel": lambda cfg, a: ok({"id": pub.create_container(
        cfg, pub.carousel_params(a.children.split(","), a.caption))}),
    "status": lambda cfg, a: ok(pub.container_status(cfg, a.container_id)),
    "wait": lambda cfg, a: ok({"id": pub.wait_ready(cfg, a.container_id, timeout=a.timeout), "status_code": "FINISHED"}),
    "publish": lambda cfg, a: ok({"media_id": pub.publish_container(cfg, a.container_id)}),
    "info": lambda cfg, a: ok(pub.media_info(cfg, a.media_id)),
    "list": lambda cfg, a: ok(pub.list_media(cfg, a.limit)),
    "comments": lambda cfg, a: ok(pub.set_comments(cfg, a.media_id, a.state == "on")),
    "delete": lambda cfg, a: ok(pub.delete_media(cfg, a.media_id)),
    "post": lambda cfg, a: post_result(pub.post_job(cfg, pub.load_job(Path(a.job)), dry_run=a.dry_run, force=a.force)),
}


def validate_only(a: Args) -> Result:
    errs = pub.validate_job(pub.load_job(Path(a.job)))
    return {"ok": not errs, "errors": errs}, (0 if not errs else 2)


def error_result(e: Exception) -> Result:
    return ({"error": str(e), "code": e.code, "subcode": e.subcode} if isinstance(e, GraphError)
            else {"error": f"{type(e).__name__}: {e}"}), 1


def run(a: Args) -> Result:
    if a.cmd == "validate":  # 설정/토큰 없이 실행 가능해야 하므로 별도 처리
        return validate_only(a)
    try:
        return HANDLERS[a.cmd](load_config(), a)
    except (GraphError, RuntimeError, TimeoutError, OSError) as e:
        return error_result(e)


def main(argv: list | None = None) -> int:
    result, code = run(build_parser(ARG_SPECS).parse_args(argv))
    print(json.dumps(result, ensure_ascii=False))
    return code


if __name__ == "__main__":
    sys.exit(main())
