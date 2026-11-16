"""Flutter 프로젝트에서 실제 Android applicationId / iOS bundle ID를 읽고 다른 소스와 대조한다."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Callable, List, Mapping, NamedTuple, Optional

from common.config import Config, default_android_id, default_ios_bundle_id, path_for, project_path
from common.effects import Effects

GRADLE_APP_ID = re.compile(r'^\s*applicationId\s*=?\s*["\']([^"\']+)["\']', re.MULTILINE)
PBX_BUNDLE_ID = re.compile(r"PRODUCT_BUNDLE_IDENTIFIER\s*=\s*\"?([^\";\s]+)\"?;")


class AppIds(NamedTuple):
    android: str
    ios: str


def android_app_id(gradle_text: str) -> Optional[str]:
    m = GRADLE_APP_ID.search(gradle_text)
    return m.group(1) if m else None


def ios_bundle_id(pbxproj_text: str) -> Optional[str]:
    """Runner 타겟 ID. 테스트/확장 타겟(접미사가 붙은 ID)은 제외하고 가장 짧은 것을 고른다."""
    ids = set(PBX_BUNDLE_ID.findall(pbxproj_text))
    return min(ids, key=len) if ids else None


def resolve_ids(
    cfg: Config,
    app: str,
    detected_android: Optional[str],
    detected_ios: Optional[str],
    override_android: Optional[str] = None,
    override_ios: Optional[str] = None,
) -> AppIds:
    """우선순위: CLI 지정 > 프로젝트 실제 값 > release.yaml org.packagePrefix 기본값."""
    return AppIds(
        override_android or detected_android or default_android_id(cfg, app),
        override_ios or detected_ios or default_ios_bundle_id(cfg, app),
    )


def mismatches(ids: AppIds, listing: Mapping[str, object]) -> List[str]:
    pairs = [("package_name", ids.android), ("bundle_id", ids.ios)]
    return [
        f"store_listing.json {key}={listing[key]} 이(가) 프로젝트 값 {actual} 과 다릅니다"
        for key, actual in pairs
        if key in listing and listing[key] != actual
    ]


def _read_first(effects: Effects, paths: List[Path], parse: Callable[[str], Optional[str]]) -> Optional[str]:
    return next((v for p in paths if effects.exists(p) for v in [parse(effects.read_text(p))] if v), None)


def detect_ids(effects: Effects, cfg: Config, repo_root: Path, app: str) -> tuple:
    base = repo_root / project_path(cfg, app)
    android = _read_first(
        effects,
        [base / "android/app/build.gradle.kts", base / "android/app/build.gradle"],
        android_app_id,
    )
    ios = _read_first(effects, [base / "ios/Runner.xcodeproj/project.pbxproj"], ios_bundle_id)
    return android, ios


def listing_mismatches(effects: Effects, cfg: Config, repo_root: Path, app: str, ids: AppIds) -> List[str]:
    listing = repo_root / path_for(cfg, "storeListing", app)
    return mismatches(ids, json.loads(effects.read_text(listing))) if effects.exists(listing) else []
