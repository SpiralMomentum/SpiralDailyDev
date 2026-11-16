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
    },
    "android": {
        "path_key": "androidMetadata",
        "locales": {"ko": "ko-KR", "en": "en-US", "ja": "ja-JP"},
        "fields": {
            "title": "title.txt",
            "short_description": "short_description.txt",
            "full_description": "full_description.txt",
        },
    },
}


def render_platform(store_text: Mapping[str, Any], platform: str) -> Dict[str, str]:
    """출력 디렉토리 기준 상대 경로 -> 내용. 빈 값은 건너뛴다."""
    spec = PLATFORMS[platform]
    return {
        f"{spec['locales'].get(lang, lang)}/{filename}": value
        for lang, data in (store_text.get(platform) or {}).items()
        for field, filename in spec["fields"].items()
        for value in [(data.get(field) or "").strip()]
        if value
    }


def render_files(cfg: Config, app: str, store_text: Mapping[str, Any], platforms: list) -> Dict[str, str]:
    """저장소 기준 상대 경로 -> 내용."""
    return {
        f"{path_for(cfg, PLATFORMS[p]['path_key'], app)}/{rel}": value
        for p in platforms
        for rel, value in render_platform(store_text, p).items()
    }


def generate(effects: Effects, cfg: Config, app: str, platforms: list, repo_root: Path = REPO_ROOT) -> int:
    listing = repo_root / path_for(cfg, "storeListing", app)
    if not effects.exists(listing):
        return fail(f"{listing} 없음")
    store_text = json.loads(effects.read_text(listing)).get("store_text")
    if not store_text:
        return fail("store_listing.json에 store_text 블록이 없습니다")

    files = render_files(cfg, app, store_text, platforms)
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
