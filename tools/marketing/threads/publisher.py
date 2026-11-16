"""Threads 게시 단계 함수 + job 단위 파이프라인 (함수형 스타일).

흐름: 검증 -> 공개 URL 확보 -> 컨테이너 생성 -> 상태 FINISHED 대기 -> threads_publish -> permalink 조회 -> 원장 기록

job 형식 (YAML 또는 JSON):
  type: text | image | video | carousel
  text: "..."                 # 또는 text_file: 경로. text 타입은 필수, 나머지는 선택
  media: [경로 또는 https URL]  # image/video 1개, carousel 2~20개, text는 없음
  link: https://...           # text 타입 전용 링크 미리보기 (선택)
  topic: 태그                  # 주제 태그 1개 (선택)
  idempotency_key: "..."      # 선택. 없으면 type + 미디어 내용 + text 해시
"""
from __future__ import annotations

import json
import re
import time
from datetime import datetime, timezone
from itertools import chain
from pathlib import Path
from typing import Any, Callable, Iterable, Mapping, Optional

from common import ledger
from common.envfile import ENV_FILE
from common.hosting import is_url, to_public_url
from common.http_api import ApiError, call, compact, logger
from threads.config import LEDGER_FILE, Config

log = logger("threads")
Job = Mapping[str, Any]
Validator = Callable[[Job], list]

IMAGE_EXT = frozenset({".jpg", ".jpeg", ".png"})
VIDEO_EXT = frozenset({".mp4", ".mov"})
TEXT_MAX = 500
LINK_MAX = 5
IMAGE_MAX_BYTES = 8 * 1024 * 1024
IMAGE_WIDTH = (320, 1440)
RATIO_MAX = 10.0  # 가로/세로 또는 세로/가로 최대 10:1
MEDIA_COUNT = {"text": (0, 0), "image": (1, 1), "video": (1, 1), "carousel": (2, 20)}
EXPECTED_KIND = {"image": "image", "video": "video"}


# ================================================================ API 호출 (부수효과)

def get(cfg: Config, path: str, **params: Any) -> dict[str, Any]:
    return call(cfg.api_base, cfg.token, "GET", path, **params)


def post(cfg: Config, path: str, **params: Any) -> dict[str, Any]:
    return call(cfg.api_base, cfg.token, "POST", path, **params)


def delete(cfg: Config, path: str, **params: Any) -> dict[str, Any]:
    return call(cfg.api_base, cfg.token, "DELETE", path, **params)


# ================================================================ job 로드

def resolve_media(base: Path, m: str) -> str:
    return m if is_url(m) else str((base / m).resolve())


def normalize_job(raw: Job, base: Path, text_from_file: Optional[str]) -> dict[str, Any]:
    """상대 경로를 job 파일 기준 절대 경로로, text_file을 text로 바꾼 새 job (순수 함수)."""
    return {**raw, "text": raw.get("text", text_from_file or ""),
            "media": [resolve_media(base, m) for m in raw.get("media") or []]}


def parse_job_text(text: str, suffix: str) -> dict[str, Any]:
    if suffix in (".yaml", ".yml"):
        import yaml  # requirements.txt 에 포함
        return yaml.safe_load(text)
    return json.loads(text)


def load_job(path: Path) -> dict[str, Any]:
    raw = parse_job_text(path.read_text(encoding="utf-8"), path.suffix)
    text_from_file = ((path.parent / raw["text_file"]).read_text(encoding="utf-8").strip()
                      if raw.get("text_file") and "text" not in raw else None)
    return normalize_job(raw, path.parent, text_from_file)


# ================================================================ 검증 (순수 함수 조합)

def media_kind(m: str) -> Optional[str]:
    ext = Path(m.split("?")[0]).suffix.lower()
    return "image" if ext in IMAGE_EXT else "video" if ext in VIDEO_EXT else None


def check_type(job: Job) -> list:
    return [] if job.get("type") in MEDIA_COUNT else [f"type 오류: {job.get('type')}"]


def check_count(job: Job) -> list:
    lo, hi = MEDIA_COUNT.get(job.get("type"), (0, 20))
    n = len(job.get("media") or [])
    return [] if lo <= n <= hi else [f"{job.get('type')}는 media {lo}~{hi}개 필요 (현재 {n})"]


def check_kinds(job: Job) -> list:
    expected = EXPECTED_KIND.get(job.get("type"))
    return list(chain.from_iterable(
        [f"지원하지 않는 미디어 확장자: {m}"] if media_kind(m) is None
        else [f"{job['type']} job에 다른 종류 미디어: {m}"] if expected and media_kind(m) != expected
        else []
        for m in job.get("media") or []))


def check_files_exist(job: Job) -> list:
    return [f"파일 없음: {m}" for m in job.get("media") or [] if not is_url(m) and not Path(m).exists()]


def image_errors(name: str, size_bytes: int, fmt: str, w: int, h: int) -> list:
    ratio = max(w / h, h / w)
    return [e for e in (
        size_bytes > IMAGE_MAX_BYTES and f"{name}: {size_bytes} bytes > 8MB",
        fmt not in ("JPEG", "PNG") and f"{name}: 포맷 {fmt} (JPEG/PNG만 허용)",
        not (IMAGE_WIDTH[0] <= w <= IMAGE_WIDTH[1]) and f"{name}: 폭 {w}px (허용 320~1440)",
        ratio > RATIO_MAX and f"{name}: 비율 {w}x{h} (최대 10:1)",
    ) if e]


def read_image_meta(path: Path) -> Optional[tuple]:
    try:
        from PIL import Image
    except ImportError:
        log("Pillow 미설치: 이미지 크기/비율 검증 생략")
        return None
    with Image.open(path) as im:
        return path.name, path.stat().st_size, im.format, im.size[0], im.size[1]


def check_images(job: Job) -> list:
    metas = (read_image_meta(Path(m)) for m in job.get("media") or []
             if not is_url(m) and media_kind(m) == "image" and Path(m).exists())
    return list(chain.from_iterable(image_errors(*meta) for meta in metas if meta))


def check_text(job: Job) -> list:
    text = job.get("text", "")
    return [e for e in (
        job.get("type") == "text" and not text.strip() and "text 타입은 text 필수",
        len(text) > TEXT_MAX and f"text {len(text)}자 > {TEXT_MAX}",
        len(re.findall(r"https?://\S+", text)) > LINK_MAX and f"본문 링크 > {LINK_MAX}",
        job.get("link") and job.get("type") != "text" and "link 는 text 타입 전용",
    ) if e]


VALIDATORS: tuple = (check_type, check_count, check_kinds, check_files_exist, check_images, check_text)


def validate_job(job: Job, validators: Iterable[Validator] = VALIDATORS) -> list:
    return list(chain.from_iterable(v(job) for v in validators))


def idempotency_key(job: Job) -> str:
    return ledger.content_key(job, "text")


# ================================================================ 컨테이너 파라미터 (순수 함수)

def text_params(text: str, link: Optional[str] = None, topic: Optional[str] = None) -> dict[str, Any]:
    return compact({"media_type": "TEXT", "text": text, "link_attachment": link, "topic_tag": topic})


def image_params(url: str, text: Optional[str] = None, carousel_item: bool = False,
                 topic: Optional[str] = None) -> dict[str, Any]:
    return compact({"media_type": "IMAGE", "image_url": url, "text": text or None, "topic_tag": topic,
                    "is_carousel_item": "true" if carousel_item else None})


def video_params(url: str, text: Optional[str] = None, carousel_item: bool = False,
                 topic: Optional[str] = None) -> dict[str, Any]:
    return compact({"media_type": "VIDEO", "video_url": url, "text": text or None, "topic_tag": topic,
                    "is_carousel_item": "true" if carousel_item else None})


def carousel_params(children: Iterable[str], text: Optional[str] = None, topic: Optional[str] = None) -> dict[str, Any]:
    return compact({"media_type": "CAROUSEL", "children": ",".join(children), "text": text or None, "topic_tag": topic})


def child_params(media: str, url: str) -> dict[str, Any]:
    return image_params(url, carousel_item=True) if media_kind(media) == "image" else video_params(url, carousel_item=True)


def wait_timeout(params: Mapping[str, Any]) -> tuple:
    return (600.0, 10.0) if "video_url" in params else (120.0, 3.0)


# ================================================================ API 단계 (부수효과)

def profile(cfg: Config) -> dict[str, Any]:
    return get(cfg, "me", fields="id,username,name")


def publishing_limit(cfg: Config) -> dict[str, Any]:
    return (get(cfg, f"{cfg.user_id}/threads_publishing_limit",
                fields="quota_usage,config,reply_quota_usage,reply_config").get("data") or [{}])[0]


def create_container(cfg: Config, params: Mapping[str, Any]) -> str:
    cid = post(cfg, f"{cfg.user_id}/threads", **params)["id"]
    log(f"컨테이너 생성 {cid} ({params.get('media_type')})")
    return cid


def container_status(cfg: Config, container_id: str) -> dict[str, Any]:
    return get(cfg, container_id, fields="id,status,error_message")


def wait_ready(cfg: Config, container_id: str, timeout: float = 120, interval: float = 3,
               sleep: Callable[[float], None] = time.sleep, clock: Callable[[], float] = time.time) -> str:
    deadline = clock() + timeout

    def poll() -> str:
        s = container_status(cfg, container_id)
        status = s.get("status")
        if status in ("FINISHED", "PUBLISHED"):
            return container_id
        if status in ("ERROR", "EXPIRED"):
            raise RuntimeError(f"컨테이너 {container_id} {status}: {s.get('error_message')}")
        if clock() > deadline:
            raise TimeoutError(f"컨테이너 {container_id} 대기 시간 초과 (마지막 상태 {status})")
        log(f"컨테이너 {container_id} 상태 {status}, {interval}s 대기")
        sleep(interval)
        return poll()
    return poll()


def create_ready(cfg: Config, params: Mapping[str, Any]) -> str:
    timeout, interval = wait_timeout(params)
    return wait_ready(cfg, create_container(cfg, params), timeout, interval)


def publish_container(cfg: Config, container_id: str) -> str:
    media_id = post(cfg, f"{cfg.user_id}/threads_publish", creation_id=container_id)["id"]
    log(f"게시 완료 media_id={media_id}")
    return media_id


def media_info(cfg: Config, media_id: str) -> dict[str, Any]:
    return get(cfg, media_id, fields="id,permalink,media_type,text,timestamp,shortcode,topic_tag")


def list_threads(cfg: Config, limit: int = 10) -> list:
    return get(cfg, f"{cfg.user_id}/threads", fields="id,permalink,media_type,timestamp,text", limit=limit).get("data", [])


def delete_thread(cfg: Config, media_id: str) -> dict[str, Any]:
    return delete(cfg, media_id)


# ================================================================ 토큰 갱신

def replace_env_value(text: str, key: str, value: str) -> str:
    """.env 텍스트에서 key 줄만 바꾼 새 텍스트 (순수 함수)."""
    lines = text.splitlines()
    found = any(line.startswith(f"{key}=") for line in lines)
    updated = [f"{key}={value}" if line.startswith(f"{key}=") else line for line in lines]
    return "\n".join(updated if found else [*updated, f"{key}={value}"]) + "\n"


def refresh_token(cfg: Config, env_file: Path = ENV_FILE) -> dict[str, Any]:
    """장기 토큰(60일) 갱신. 발급 24시간 이후부터 가능. 새 토큰은 .env에만 쓰고 출력하지 않는다."""
    r = call(cfg.api_host, cfg.token, "GET", "refresh_access_token", grant_type="th_refresh_token")
    env_file.write_text(replace_env_value(env_file.read_text(encoding="utf-8"), "MKT_THREADS_TOKEN", r["access_token"]),
                        encoding="utf-8")
    return {"refreshed": True, "expires_in_days": round(r.get("expires_in", 0) / 86400, 1), "saved_to": str(env_file)}


# ================================================================ OAuth (삭제 등 토큰 생성기에 없는 권한이 필요할 때)
# 2026-11-12 확인: 콘솔 "사용자 토큰 생성기" 토큰의 scopes =
#   threads_basic, threads_content_publish, threads_manage_replies, threads_manage_insights, threads_read_replies
# threads_delete 가 없어 DELETE 가 code 10(403). Authorization Window 로 받은 토큰이 필요하다.

OAUTH_SCOPES = ("threads_basic", "threads_content_publish", "threads_delete",
                "threads_manage_replies", "threads_read_replies", "threads_manage_insights")


def authorize_url(app_id: str, redirect_uri: str, scopes: Iterable[str] = OAUTH_SCOPES) -> str:
    """사용자가 브라우저에서 열 인증 URL (순수 함수)."""
    from urllib.parse import urlencode
    return "https://threads.net/oauth/authorize?" + urlencode({
        "client_id": app_id, "redirect_uri": redirect_uri, "scope": ",".join(scopes), "response_type": "code"})


def extract_code(code_or_url: str) -> str:
    """리디렉션된 전체 URL 또는 code 값 -> code (순수 함수). 끝의 '#_' 는 제거."""
    from urllib.parse import parse_qs, urlparse
    raw = parse_qs(urlparse(code_or_url).query).get("code", [code_or_url])[0] if "?" in code_or_url else code_or_url
    return raw.split("#")[0].strip()


def exchange_code(cfg: Config, app_id: str, app_secret: str, redirect_uri: str, code_or_url: str,
                  env_file: Path = ENV_FILE) -> dict[str, Any]:
    """code -> 단기 토큰(1시간) -> 장기 토큰(60일) 교환 후 .env 저장. 토큰은 출력하지 않는다."""
    short = call(cfg.api_host, "", "POST", "oauth/access_token", client_id=app_id, client_secret=app_secret,
                 grant_type="authorization_code", redirect_uri=redirect_uri, code=extract_code(code_or_url))
    long = call(cfg.api_host, short["access_token"], "GET", "access_token",
                grant_type="th_exchange_token", client_secret=app_secret)
    text = env_file.read_text(encoding="utf-8")
    text = replace_env_value(text, "MKT_THREADS_TOKEN", long["access_token"])
    text = replace_env_value(text, "MKT_THREADS_USER_ID", str(short.get("user_id") or cfg.user_id))
    env_file.write_text(text, encoding="utf-8")
    return {"exchanged": True, "user_id": short.get("user_id"),
            "expires_in_days": round(long.get("expires_in", 0) / 86400, 1), "saved_to": str(env_file)}


def token_scopes(cfg: Config) -> dict[str, Any]:
    d = get(cfg, "debug_token", input_token=cfg.token).get("data", {})
    return {k: d.get(k) for k in ("is_valid", "expires_at", "scopes")}


# ================================================================ job 게시 파이프라인

def root_params(cfg: Config, job: Job, urls: list) -> dict[str, Any]:
    text, topic = job.get("text", ""), job.get("topic")
    builders: Mapping[str, Callable[[], dict]] = {
        "text": lambda: text_params(text, job.get("link"), topic),
        "image": lambda: image_params(urls[0], text, topic=topic),
        "video": lambda: video_params(urls[0], text, topic=topic),
        "carousel": lambda: carousel_params(
            [create_ready(cfg, child_params(m, u)) for m, u in zip(job["media"], urls)], text, topic),
    }
    return builders[job["type"]]()


def build_and_publish(cfg: Config, job: Job) -> str:
    urls = [to_public_url(m, cfg.host_provider) for m in job.get("media") or []]
    return publish_container(cfg, create_ready(cfg, root_params(cfg, job, urls)))


def quota_left(limit: Mapping[str, Any]) -> tuple:
    return limit.get("quota_usage", 0), limit.get("config", {}).get("quota_total", 250)


def ledger_row(key: str, job: Job, media_id: str, info: Mapping[str, Any], now: datetime) -> dict[str, Any]:
    return {
        "status": "published", "key": key, "media_id": media_id, "permalink": info.get("permalink"),
        "type": job["type"], "published_at": info.get("timestamp"),
        "recorded_at": now.isoformat(timespec="seconds"), "job_name": job.get("name"),
    }


def deleted_row(media_id: str, now: datetime) -> dict[str, Any]:
    return {"status": "deleted", "media_id": media_id, "recorded_at": now.isoformat(timespec="seconds")}


def post_job(cfg: Config, job: Job, *, dry_run: bool = False, force: bool = False) -> Mapping[str, Any]:
    errs = validate_job(job)
    if errs:
        return {"status": "invalid", "errors": errs}

    key = idempotency_key(job)
    prev = ledger.find_published(ledger.read_ledger(LEDGER_FILE), key)
    if prev and not force:
        log(f"이미 게시된 job (key={key}) -> 건너뜀")
        return {"status": "skipped", "key": key, "media_id": prev["media_id"], "permalink": prev.get("permalink")}
    if dry_run:
        return {"status": "dry_run", "key": key, "type": job["type"], "media": list(job.get("media") or [])}

    used, total = quota_left(publishing_limit(cfg))
    if used >= total:
        return {"status": "quota_exceeded", "quota_usage": used, "quota_total": total}

    media_id = build_and_publish(cfg, job)
    return ledger.append_ledger(
        ledger_row(key, job, media_id, media_info(cfg, media_id), datetime.now(timezone.utc)), LEDGER_FILE)


def delete_and_record(cfg: Config, media_id: str) -> Mapping[str, Any]:
    result = delete_thread(cfg, media_id)
    if result.get("success"):
        ledger.append_ledger(deleted_row(media_id, datetime.now(timezone.utc)), LEDGER_FILE)
    return result


__all__ = ["ApiError"]
