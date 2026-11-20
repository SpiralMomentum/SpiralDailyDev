"""Instagram 게시 단계 함수 + job 단위 파이프라인 (함수형 스타일).

흐름: 검증 -> 공개 URL 확보 -> 컨테이너 생성 -> 상태 FINISHED 대기 -> media_publish -> permalink 조회 -> 원장 기록

원칙:
- job, 원장 행은 불변으로 다룬다 (새 dict를 만들어 반환, 입력 수정 금지).
- 검증 규칙은 job -> 오류 목록을 돌려주는 순수 함수들의 조합이다.
- API 파라미터 구성은 순수 함수, HTTP/파일/대기는 이름에 드러나는 부수효과 함수로 분리한다.

job 형식 (YAML 또는 JSON):
  type: image | carousel | reel
  media: [로컬 경로 또는 https URL, ...]   # image/reel 1개, carousel 2~10개
  caption: "..."                         # 또는 caption_file: 경로
  share_to_feed: true                    # reel 전용 (기본 true)
  cover: 경로/URL                         # reel 전용, 선택
  idempotency_key: "..."                 # 선택. 없으면 type+media 내용+caption 해시
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
from common.hosting import is_url, to_public_url
from instagram import graph_api as api
from instagram.config import LEDGER_FILE, Config
from instagram.graph_api import log

Job = Mapping[str, Any]
Row = Mapping[str, Any]
Validator = Callable[[Job], list]

IMAGE_EXT = frozenset({".jpg", ".jpeg"})
VIDEO_EXT = frozenset({".mp4", ".mov"})
CAPTION_MAX, HASHTAG_MAX, MENTION_MAX = 2200, 30, 20
IMAGE_MAX_BYTES = 8 * 1024 * 1024
RATIO_MIN, RATIO_MAX = 4 / 5, 1.91  # 피드 이미지 가로/세로 허용 범위
MEDIA_COUNT = {"image": (1, 1), "reel": (1, 1), "carousel": (2, 10)}
EXPECTED_KIND = {"image": "image", "reel": "video"}


# ================================================================ job 로드 (순수 변환 + 파일 읽기)

def resolve_media(base: Path, m: str) -> str:
    return m if is_url(m) else str((base / m).resolve())


def normalize_job(raw: Job, base: Path, caption_text: Optional[str]) -> dict[str, Any]:
    """상대 경로를 job 파일 기준 절대 경로로, caption_file을 caption으로 바꾼 새 job (순수 함수)."""
    return {
        **raw,
        "caption": raw.get("caption", caption_text or ""),
        "media": [resolve_media(base, m) for m in raw.get("media", [])],
        **({"cover": resolve_media(base, raw["cover"])} if raw.get("cover") else {}),
    }


def parse_job_text(text: str, suffix: str) -> dict[str, Any]:
    if suffix in (".yaml", ".yml"):
        import yaml  # requirements.txt 에 포함
        return yaml.safe_load(text)
    return json.loads(text)


def load_job(path: Path) -> dict[str, Any]:
    raw = parse_job_text(path.read_text(encoding="utf-8"), path.suffix)
    caption_text = ((path.parent / raw["caption_file"]).read_text(encoding="utf-8").strip()
                    if raw.get("caption_file") and "caption" not in raw else None)
    return normalize_job(raw, path.parent, caption_text)


# ================================================================ 검증 (순수 함수 조합)

def media_kind(m: str) -> Optional[str]:
    ext = Path(m.split("?")[0]).suffix.lower()
    return "image" if ext in IMAGE_EXT else "video" if ext in VIDEO_EXT else None


def check_type(job: Job) -> list:
    return [] if job.get("type") in MEDIA_COUNT else [f"type 오류: {job.get('type')}"]


def check_count(job: Job) -> list:
    lo, hi = MEDIA_COUNT.get(job.get("type"), (1, 10))
    n = len(job.get("media") or [])
    return [] if lo <= n <= hi else [f"{job.get('type')}는 media {lo}~{hi}개 필요 (현재 {n})"]


def check_kinds(job: Job) -> list:
    expected = EXPECTED_KIND.get(job.get("type"))
    return list(chain.from_iterable(
        [f"지원하지 않는 미디어 확장자: {m} (이미지는 JPEG만 허용)"] if media_kind(m) is None
        else [f"{job['type']} job에 다른 종류 미디어: {m}"] if expected and media_kind(m) != expected
        else []
        for m in job.get("media") or []))


def check_files_exist(job: Job) -> list:
    return [f"파일 없음: {m}" for m in job.get("media") or [] if not is_url(m) and not Path(m).exists()]


def image_errors(name: str, size_bytes: int, fmt: str, w: int, h: int) -> list:
    """이미지 메타데이터 -> 오류 목록 (순수 함수)."""
    ratio = w / h
    return [e for e in (
        size_bytes > IMAGE_MAX_BYTES and f"{name}: {size_bytes} bytes > 8MB",
        fmt != "JPEG" and f"{name}: 포맷 {fmt} (JPEG만 허용)",
        not (RATIO_MIN - 0.01 <= ratio <= RATIO_MAX + 0.01) and f"{name}: 비율 {w}x{h}={ratio:.3f} (허용 0.8~1.91)",
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
    local_images = (Path(m) for m in job.get("media") or []
                    if not is_url(m) and media_kind(m) == "image" and Path(m).exists())
    metas = (read_image_meta(p) for p in local_images)
    return list(chain.from_iterable(image_errors(*meta) for meta in metas if meta))


def check_caption(job: Job) -> list:
    cap = job.get("caption", "")
    return [e for e in (
        len(cap) > CAPTION_MAX and f"caption {len(cap)}자 > {CAPTION_MAX}",
        len(re.findall(r"#\w+", cap)) > HASHTAG_MAX and f"해시태그 > {HASHTAG_MAX}",
        len(re.findall(r"@\w+", cap)) > MENTION_MAX and f"멘션 > {MENTION_MAX}",
    ) if e]


VALIDATORS: tuple = (check_type, check_count, check_kinds, check_files_exist, check_images, check_caption)


def validate_job(job: Job, validators: Iterable[Validator] = VALIDATORS) -> list:
    return list(chain.from_iterable(v(job) for v in validators))


def idempotency_key(job: Job) -> str:
    return ledger.content_key(job, "caption")


# ================================================================ 원장 (중복 게시 방지)

def read_ledger(path: Path = LEDGER_FILE) -> tuple:
    return ledger.read_ledger(path)


def append_ledger(row: Row, path: Path = LEDGER_FILE) -> Row:
    return ledger.append_ledger(row, path)


find_published = ledger.find_published
parse_ledger = ledger.parse_ledger


def ledger_row(key: str, job: Job, media_id: str, info: Mapping[str, Any], now: datetime) -> dict[str, Any]:
    return {
        "status": "published", "key": key, "media_id": media_id, "permalink": info.get("permalink"),
        "type": job["type"], "published_at": info.get("timestamp"),
        "recorded_at": now.isoformat(timespec="seconds"), "job_name": job.get("name"),
    }


# ================================================================ 컨테이너 파라미터 (순수 함수)

def image_params(url: str, caption: Optional[str] = None, carousel_item: bool = False) -> dict[str, Any]:
    return api.compact({"image_url": url, "caption": caption, "is_carousel_item": "true" if carousel_item else None})


def video_params(url: str, caption: Optional[str] = None, *, reel: bool = False, carousel_item: bool = False,
                 cover_url: Optional[str] = None, share_to_feed: bool = True) -> dict[str, Any]:
    return api.compact({
        "media_type": "REELS" if reel else "VIDEO", "video_url": url, "caption": caption, "cover_url": cover_url,
        "is_carousel_item": "true" if carousel_item else None,
        "share_to_feed": str(share_to_feed).lower() if reel else None,
    })


def carousel_params(children: Iterable[str], caption: Optional[str]) -> dict[str, Any]:
    return api.compact({"media_type": "CAROUSEL", "children": ",".join(children), "caption": caption})


def child_params(media: str, url: str) -> dict[str, Any]:
    return image_params(url, carousel_item=True) if media_kind(media) == "image" else video_params(url, carousel_item=True)


def wait_timeout(params: Mapping[str, Any], video_timeout: float) -> tuple:
    return (video_timeout, 10.0) if "video_url" in params else (120.0, 5.0)


# ================================================================ API 단계 (부수효과)

def account_info(cfg: Config) -> dict[str, Any]:
    return api.get(cfg, cfg.ig_user_id, fields="id,username,name,media_count,followers_count")


def publishing_limit(cfg: Config) -> dict[str, Any]:
    return (api.get(cfg, f"{cfg.ig_user_id}/content_publishing_limit", fields="config,quota_usage").get("data") or [{}])[0]


def create_container(cfg: Config, params: Mapping[str, Any]) -> str:
    cid = api.post(cfg, f"{cfg.ig_user_id}/media", **params)["id"]
    log(f"컨테이너 생성 {cid} ({params.get('media_type', 'IMAGE')})")
    return cid


def container_status(cfg: Config, container_id: str) -> dict[str, Any]:
    return api.get(cfg, container_id, fields="id,status_code,status")


def wait_ready(cfg: Config, container_id: str, timeout: float = 300, interval: float = 5,
               sleep: Callable[[float], None] = time.sleep, clock: Callable[[], float] = time.time) -> str:
    deadline = clock() + timeout

    def poll() -> str:
        s = container_status(cfg, container_id)
        code = s.get("status_code")
        if code in ("FINISHED", "PUBLISHED"):  # PUBLISHED: 이미 게시된 컨테이너 (재게시해도 같은 media_id 반환)
            return container_id
        if code in ("ERROR", "EXPIRED"):
            raise RuntimeError(f"컨테이너 {container_id} {code}: {s.get('status')}")
        if clock() > deadline:
            raise TimeoutError(f"컨테이너 {container_id} 대기 시간 초과 (마지막 상태 {code})")
        log(f"컨테이너 {container_id} 상태 {code}, {interval}s 대기")
        sleep(interval)
        return poll()
    return poll()


def create_ready(cfg: Config, params: Mapping[str, Any], video_timeout: float = 600) -> str:
    timeout, interval = wait_timeout(params, video_timeout)
    return wait_ready(cfg, create_container(cfg, params), timeout, interval)


def publish_container(cfg: Config, container_id: str) -> str:
    media_id = api.post(cfg, f"{cfg.ig_user_id}/media_publish", creation_id=container_id)["id"]
    log(f"게시 완료 media_id={media_id}")
    return media_id


def media_info(cfg: Config, media_id: str) -> dict[str, Any]:
    return api.get(cfg, media_id, fields="id,permalink,media_type,media_product_type,timestamp,caption")


def list_media(cfg: Config, limit: int = 10) -> list:
    return api.get(cfg, f"{cfg.ig_user_id}/media", fields="id,permalink,media_type,timestamp", limit=limit).get("data", [])


def set_comments(cfg: Config, media_id: str, enabled: bool) -> dict[str, Any]:
    # 게시 후 API로 바꿀 수 있는 것은 댓글 허용 여부뿐. 캡션 수정은 code 3 Unknown method (2026-11-12 확인)
    return api.post(cfg, media_id, comment_enabled=str(enabled).lower())


def delete_media(cfg: Config, media_id: str) -> dict[str, Any]:
    # 계정/권한에 따라 지원되지 않을 수 있음. 실패 시 인스타 앱에서 직접 삭제.
    return api.delete(cfg, media_id)


# ================================================================ job 게시 파이프라인

def root_params(cfg: Config, job: Job, urls: list) -> dict[str, Any]:
    """job 종류별 최종 컨테이너 파라미터. 캐러셀은 자식 컨테이너를 먼저 만든다."""
    caption = job.get("caption", "")
    builders: Mapping[str, Callable[[], dict]] = {
        "image": lambda: image_params(urls[0], caption),
        "reel": lambda: video_params(
            urls[0], caption, reel=True, share_to_feed=bool(job.get("share_to_feed", True)),
            cover_url=to_public_url(job["cover"], cfg.host_provider) if job.get("cover") else None),
        "carousel": lambda: carousel_params(
            [create_ready(cfg, child_params(m, u)) for m, u in zip(job["media"], urls)], caption),
    }
    return builders[job["type"]]()


def build_and_publish(cfg: Config, job: Job) -> str:
    urls = [to_public_url(m, cfg.host_provider) for m in job["media"]]
    return publish_container(cfg, create_ready(cfg, root_params(cfg, job, urls)))


def quota_left(limit: Mapping[str, Any]) -> tuple:
    return limit.get("quota_usage", 0), limit.get("config", {}).get("quota_total", 100)


def post_job(cfg: Config, job: Job, *, dry_run: bool = False, force: bool = False) -> Mapping[str, Any]:
    errs = validate_job(job)
    if errs:
        return {"status": "invalid", "errors": errs}

    key = idempotency_key(job)
    prev = find_published(read_ledger(), key)
    if prev and not force:
        log(f"이미 게시된 job (key={key}) -> 건너뜀")
        return {"status": "skipped", "key": key, "media_id": prev["media_id"], "permalink": prev.get("permalink")}
    if dry_run:
        return {"status": "dry_run", "key": key, "type": job["type"], "media": list(job["media"])}

    used, total = quota_left(publishing_limit(cfg))
    if used >= total:
        return {"status": "quota_exceeded", "quota_usage": used, "quota_total": total}

    media_id = build_and_publish(cfg, job)
    return append_ledger(ledger_row(key, job, media_id, media_info(cfg, media_id), datetime.now(timezone.utc)))
