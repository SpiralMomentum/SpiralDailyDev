#!/usr/bin/env python3
"""release.yaml 앱 목록을 CI matrix JSON으로 출력한다.

  all-apps:    전체 앱 (테스트용)
  deploy-apps: ci.excludeFromRelease 제외 (배포용)

APPS_FILTER(쉼표 구분)로 범위를 좁히고, GITHUB_OUTPUT이 있으면 거기에도 쓴다.
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from typing import List, Tuple

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from common.config import Config, load_config


def app_lists(cfg: Config, apps_filter: str = "") -> Tuple[List[str], List[str]]:
    apps = cfg.get("apps") or {}
    allowed = {a.strip() for a in apps_filter.split(",") if a.strip()}
    keep = (lambda a: a in allowed) if allowed else (lambda a: True)
    all_apps = sorted(a for a in apps if keep(a))
    deploy = [a for a in all_apps if not (apps[a].get("ci") or {}).get("excludeFromRelease", False)]
    return all_apps, deploy


def render_outputs(all_apps: List[str], deploy: List[str]) -> str:
    return f"all-apps={json.dumps(all_apps)}\ndeploy-apps={json.dumps(deploy)}\n"


def main() -> int:
    text = render_outputs(*app_lists(load_config(), os.environ.get("APPS_FILTER", "")))
    github_output = os.environ.get("GITHUB_OUTPUT")
    if github_output:
        with open(github_output, "a") as fh:
            fh.write(text)
    print(text, end="")
    return 0


if __name__ == "__main__":
    sys.exit(main())
