#!/usr/bin/env python3
"""store_listing.json의 store_text 블록을 Fastlane 메타데이터 파일로 렌더링한다.

입력/출력 경로는 release.yaml paths(storeListing, iosMetadata, androidMetadata)를 따른다.

Usage:
  python3 tools/store/listing/generate_metadata.py --app daily_memo [--platform ios|android] [--dry-run]
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any, Dict, Mapping

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from common.config import REPO_ROOT, Config, load_config, path_for
from common.effects import Effects, done, effects_for, fail

PLATFORMS: Dict[str, Dict[str, Any]] = {
    "ios": {
        "path_key": "iosMetadata",
        "locales": {"ko": "ko", "en": "en-US", "ja": "ja"},
        "fields": {
            "name": "name.txt",
            "subtitle": "subtitle.txt",
            "keywords": "keywords.txt",
            "promotional_text": "promotional_text.txt",
            "description": "description.txt",
        },
        # App Store Connect 글자 수 제한
        "limits": {"name": 30, "subtitle": 30, "keywords": 100, "promotional_text": 170, "description": 4000},
    },
    "android": {
        "path_key": "androidMetadata",
        "locales": {"ko": "ko-KR", "en": "en-US", "ja": "ja-JP"},
        "fields": {
            "title": "title.txt",
            "short_description": "short_description.txt",
            "full_description": "full_description.txt",
        },
        # Google Play 글자 수 제한 (넘으면 업로드 시 'too long' 으로 거절된다)
        "limits": {"title": 30, "short_description": 80, "full_description": 4000},
    },
}


def length_errors(listing: Mapping[str, Any], platforms: list) -> list:
    return [
        f"{p}/{lang}/{field}: {len(value)}자 (제한 {limit}자) — {value[:40]}"
        for p in platforms
        for lang, data in ((listing.get("store_text") or {}).get(p) or {}).items()
        for field, limit in PLATFORMS[p]["limits"].items()
        for value in [(data.get(field) or "").strip()]
        if len(value) > limit
    ]


# store_listing.json 최상위 URL -> 로케일마다 같은 값으로 쓰는 파일 (Android supply에는 해당 파일이 없다)
URL_FILES = {
    "ios": {"privacy_policy_url": "privacy_url.txt", "support_url": "support_url.txt", "marketing_url": "marketing_url.txt"},
    "android": {},
}


def render_platform(listing: Mapping[str, Any], platform: str) -> Dict[str, str]:
    """출력 디렉토리 기준 상대 경로 -> 내용. 빈 값은 건너뛴다."""
    spec = PLATFORMS[platform]
    per_locale = (listing.get("store_text") or {}).get(platform) or {}
    urls = {name: listing.get(key) for key, name in URL_FILES[platform].items()}
    return {
        f"{spec['locales'].get(lang, lang)}/{filename}": value
        for lang, data in per_locale.items()
        for filename, raw in [*((f, data.get(k)) for k, f in spec["fields"].items()), *urls.items()]
        for value in [(raw or "").strip()]
        if value
    }


def render_files(cfg: Config, app: str, listing: Mapping[str, Any], platforms: list) -> Dict[str, str]:
    """저장소 기준 상대 경로 -> 내용."""
    return {
        f"{path_for(cfg, PLATFORMS[p]['path_key'], app)}/{rel}": value
        for p in platforms
        for rel, value in render_platform(listing, p).items()
    }


def generate(effects: Effects, cfg: Config, app: str, platforms: list, repo_root: Path = REPO_ROOT) -> int:
    listing = repo_root / path_for(cfg, "storeListing", app)
    if not effects.exists(listing):
        return fail(f"{listing} 없음")
    data = json.loads(effects.read_text(listing))
    if not data.get("store_text"):
        return fail("store_listing.json에 store_text 블록이 없습니다")

    too_long = length_errors(data, platforms)
    if too_long:
        return fail("스토어 글자 수 제한 초과 — store_listing.json을 고친 뒤 다시 실행하세요:\n  " + "\n  ".join(too_long))

    files = render_files(cfg, app, data, platforms)
    for rel, value in files.items():
        effects.write_text(repo_root / rel, value)
    done(effects, f"[{app}] {len(files)}개 파일 작성 완료")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="store_listing.json -> fastlane 메타데이터")
    parser.add_argument("--app", required=True)
    parser.add_argument("--platform", choices=["ios", "android", "all"], default="all")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    platforms = list(PLATFORMS) if args.platform == "all" else [args.platform]
    return generate(effects_for(args.dry_run), load_config(), args.app, platforms)


if __name__ == "__main__":
    sys.exit(main())
