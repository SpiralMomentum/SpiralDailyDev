"""release.yaml에 신규 앱 항목을 추가한다."""

from __future__ import annotations

from pathlib import Path
from typing import Any, Dict, List, Tuple

import yaml

from common.config import Config, default, path_for
from common.effects import Effects


def new_entry(
    cfg: Config,
    app: str,
    display_name: str,
    android_id: str,
    ios_bundle_id: str,
    exclude_from_release: bool,
    coverage_threshold: int,
) -> Dict[str, Any]:
    ci: Dict[str, Any] = {
        **({"excludeFromRelease": True} if exclude_from_release else {}),
        **({"coverageThreshold": coverage_threshold} if coverage_threshold != default(cfg, "coverageThreshold") else {}),
    }
    store_dir = path_for(cfg, "storeMetadata", app)
    return {
        "appId": android_id,
        "iosBundleId": ios_bundle_id,
        "displayName": display_name,
        "projectPath": f"apps/{app}",
        "ci": ci,
        "metadata": {"android": f"{store_dir}/android.yaml", "ios": f"{store_dir}/ios.yaml"},
        "autoGenerateIcon": False,
        "autoCaptureScreenshots": False,
        "build": {
            "android": {"command": ["flutter", "build", "appbundle", "--release"]},
            "ios": {"command": ["flutter", "build", "ipa", "--release"]},
        },
        "fastlane": {"androidLane": "android_play_production", "iosLane": "ios_appstore_release"},
    }


def with_entry(cfg: Config, app: str, entry: Dict[str, Any]) -> Dict[str, Any]:
    return {**cfg, "apps": {**(cfg.get("apps") or {}), app: entry}}


def leading_comments(text: str) -> List[str]:
    lines = text.splitlines()
    return lines[: next((i for i, l in enumerate(lines) if not l.startswith("#")), len(lines))]


def render(original_text: str, cfg: Config) -> str:
    body = yaml.dump(dict(cfg), sort_keys=False, default_flow_style=False, allow_unicode=True)
    return "".join(f"{c}\n" for c in leading_comments(original_text)) + body


def add_release_entry(
    effects: Effects, config_path: Path, cfg: Config, app: str, entry: Dict[str, Any]
) -> Tuple[Config, str]:
    """(갱신된 설정, 결과 메시지). 이미 등록된 앱이면 설정을 그대로 돌려준다."""
    if app in (cfg.get("apps") or {}):
        return cfg, f"'{app}'은 이미 release.yaml에 등록되어 있습니다"
    updated = with_entry(cfg, app, entry)
    effects.write_text(config_path, render(effects.read_text(config_path), updated))
    return updated, f"release.yaml에 '{app}' 항목 추가 (appId {entry['appId']}, iosBundleId {entry['iosBundleId']})"
