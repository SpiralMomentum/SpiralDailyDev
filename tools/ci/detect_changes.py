#!/usr/bin/env python3
"""release.yaml의 projectPath로 dorny/paths-filter YAML을 stdout에 출력한다.

사용법:
    python3 tools/ci/detect_changes.py > /tmp/filters.yml
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from common.config import Config, load_config, project_path


def render_filters(cfg: Config) -> str:
    return "\n".join(
        f"{app}:\n  - '{project_path(cfg, app)}/**'\n  - 'packages/**'"
        for app in sorted(cfg.get("apps") or {})
    )


def main() -> int:
    print(render_filters(load_config()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
