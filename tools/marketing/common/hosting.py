"""로컬 미디어 파일 -> Instagram이 가져갈 수 있는 공개 URL.

Instagram 게시 API는 파일 업로드를 받지 않고 공개 URL만 받는다.

제공자 (MKT_IG_MEDIA_HOST):
- uguu : uguu.se 임시 호스팅 (보존 약 3시간, 128MB). 테스트용. 2026-11-12 게시 성공 확인.
- none : 업로드하지 않음. job의 media에 https URL을 직접 넣어야 한다.

2026-11-12 실패 사례 (사용 금지):
- catbox.moe : 업로드는 되지만 files.catbox.moe DNS 해석 실패, Meta 측 code 1 unknown error
- tmpfiles.org : /dl/ 링크가 HTML 페이지로 302 리다이렉트되어 이미지가 아님

운영 단계에서는 자체 스토리지(S3/R2/GCS 공개 버킷) 업로더를 UPLOADERS에 추가해 MKT_STORAGE_* 로 연결한다.
"""
from __future__ import annotations

import json
import mimetypes
import urllib.request
import uuid
from pathlib import Path
from typing import Callable, Mapping

from common.http_api import log

UA = "spiral-marketing-pipeline/1.0"
Uploader = Callable[[Path], str]


# ---------------------------------------------------------------- 순수 함수

def is_url(s: str) -> bool:
    return s.startswith(("https://", "http://"))


def multipart(field: str, filename: str, content: bytes, boundary: str) -> tuple[bytes, str]:
    ctype = mimetypes.guess_type(filename)[0] or "application/octet-stream"
    head = (f"--{boundary}\r\nContent-Disposition: form-data; name=\"{field}\"; filename=\"{filename}\"\r\n"
            f"Content-Type: {ctype}\r\n\r\n").encode()
    return head + content + f"\r\n--{boundary}--\r\n".encode(), f"multipart/form-data; boundary={boundary}"


def check_media_response(url: str, final_url: str, ctype: str) -> str:
    if final_url != url:
        raise RuntimeError(f"공개 URL이 리다이렉트됨: {url} -> {final_url}")
    if not ctype.startswith(("image/", "video/")):
        raise RuntimeError(f"공개 URL이 미디어가 아님: content-type={ctype}")
    return ctype


# ---------------------------------------------------------------- 부수효과

def upload_uguu(path: Path) -> str:
    body, ctype = multipart("files[]", path.name, path.read_bytes(), uuid.uuid4().hex)
    req = urllib.request.Request("https://uguu.se/upload", data=body, method="POST",
                                 headers={"Content-Type": ctype, "User-Agent": UA})
    with urllib.request.urlopen(req, timeout=300) as resp:
        data = json.loads(resp.read().decode())
    if not data.get("success"):
        raise RuntimeError(f"uguu 업로드 실패: {data}")
    return data["files"][0]["url"]


def upload_none(path: Path) -> str:
    raise RuntimeError(f"MKT_IG_MEDIA_HOST=none 인데 로컬 파일이 지정됨: {path}")


UPLOADERS: Mapping[str, Uploader] = {"uguu": upload_uguu, "none": upload_none}


def verify_public_url(url: str) -> str:
    """URL이 리다이렉트 없이 이미지/영상 바이트를 돌려주는지 확인. content-type 반환."""
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Range": "bytes=0-1023"})
    with urllib.request.urlopen(req, timeout=60) as resp:
        resp.read(1024)
        return check_media_response(url, resp.geturl(), resp.headers.get("Content-Type", ""))


def to_public_url(media: str, provider: str) -> str:
    if is_url(media):
        verify_public_url(media)
        return media
    path = Path(media)
    if not path.exists():
        raise FileNotFoundError(media)
    uploader = UPLOADERS.get(provider)
    if uploader is None:
        raise RuntimeError(f"알 수 없는 MKT_IG_MEDIA_HOST: {provider}")
    url = uploader(path)
    log(f"업로드 {path.name} -> {url} ({verify_public_url(url)})")
    return url
