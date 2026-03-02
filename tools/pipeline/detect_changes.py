#!/usr/bin/env python3
"""release.yaml의 projectPath로 dorny/paths-filter YAML을 stdout에 출력한다.

사용법:
    python3 tools/pipeline/detect_changes.py > /tmp/filters.yml

출력 예시:
    daily_memo:
      - 'apps/daily_memo/**'
      - 'packages/**'
    film_archive:
      - 'apps/film_archive/**'
      - 'packages/**'
"""

from __future__ import annotations

import sys
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent.parent


def main() -> int:
    config_path = REPO_ROOT / "release.yaml"
    with config_path.open("r", encoding="utf-8") as fh:
        config = yaml.safe_load(fh)

    apps = config.get("apps", {})
    lines: list[str] = []

    for app_name in sorted(apps.keys()):
        app_config = apps[app_name]
        project_path = app_config.get("projectPath", f"apps/{app_name}")
        lines.append(f"{app_name}:")
        lines.append(f"  - '{project_path}/**'")
        lines.append(f"  - 'packages/**'")

    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    sys.exit(main())
