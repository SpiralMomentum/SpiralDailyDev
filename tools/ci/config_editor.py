"""release.yaml에 앱 항목을 추가한다."""

from __future__ import annotations

from pathlib import Path
from typing import Any, Dict

import yaml

from name_utils import snake_to_camel


def add_app_to_release_config(
    config_path: Path,
    *,
    app_name: str,
    display_name: str,
    app_id: str | None = None,
    ios_bundle_id: str | None = None,
    dry_run: bool = True,
) -> None:
    """release.yaml의 apps 섹션에 새 앱 항목을 추가한다.

    Args:
        config_path: release.yaml 경로
        app_name: snake_case 앱 이름
        display_name: 앱 표시 이름
        app_id: Android application ID (기본값: com.spiraldev.{app_name})
        ios_bundle_id: iOS bundle ID (기본값: com.spiraldev.{camelCase})
        dry_run: True면 변경 없이 예정 작업만 출력
    """
    resolved_app_id = app_id or f"com.spiraldev.{app_name}"
    resolved_ios_bundle_id = ios_bundle_id or f"com.spiraldev.{snake_to_camel(app_name)}"

    text = config_path.read_text(encoding="utf-8")
    config: Dict[str, Any] = yaml.safe_load(text)

    apps = config.get("apps", {})
    if app_name in apps:
        raise ValueError(f"'{app_name}'은 이미 release.yaml에 등록되어 있습니다")

    # 첫 줄 주석 보존
    first_comment_lines: list[str] = []
    for line in text.splitlines():
        if line.startswith("#"):
            first_comment_lines.append(line)
        else:
            break

    new_entry: Dict[str, Any] = {
        "appId": resolved_app_id,
        "iosBundleId": resolved_ios_bundle_id,
        "displayName": display_name,
        "projectPath": f"apps/{app_name}",
        "metadata": {
            "android": f"store_metadata/{app_name}/android.yaml",
            "ios": f"store_metadata/{app_name}/ios.yaml",
        },
        "autoGenerateIcon": False,
        "autoCaptureScreenshots": False,
        "build": {
            "android": {
                "command": ["flutter", "build", "appbundle", "--release"],
            },
            "ios": {
                "command": ["flutter", "build", "ipa", "--release"],
            },
        },
        "fastlane": {
            "androidLane": "android_play_production",
            "iosLane": "ios_appstore_release",
        },
    }

    apps[app_name] = new_entry
    config["apps"] = apps

    output = yaml.dump(config, sort_keys=False, default_flow_style=False, allow_unicode=True)

    if first_comment_lines:
        output = "\n".join(first_comment_lines) + "\n" + output

    if dry_run:
        print(f"[dry-run] release.yaml에 '{app_name}' 항목 추가 예정")
        print(f"  appId: {resolved_app_id}")
        print(f"  iosBundleId: {resolved_ios_bundle_id}")
        print(f"  displayName: {display_name}")
        return

    config_path.write_text(output, encoding="utf-8")
    print(f"release.yaml에 '{app_name}' 항목을 추가했습니다")
