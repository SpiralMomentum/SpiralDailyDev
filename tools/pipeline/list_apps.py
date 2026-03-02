#!/usr/bin/env python3
"""release.yaml에서 앱 목록을 읽어 GITHUB_OUTPUT에 JSON으로 출력한다.

CI matrix 생성용:
  - all-apps:    전체 앱 (테스트용)
  - deploy-apps: excludeFromRelease 제외 (배포용)

로컬 실행 시 stdout에 JSON을 출력한다.
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent.parent


def main() -> int:
    config_path = REPO_ROOT / "release.yaml"
    with config_path.open("r", encoding="utf-8") as fh:
        config = yaml.safe_load(fh)

    apps = config.get("apps", {})
    all_apps = sorted(apps.keys())
    deploy_apps = sorted(
        name
        for name, cfg in apps.items()
        if not (cfg.get("ci") or {}).get("excludeFromRelease", False)
    )

    all_json = json.dumps(all_apps)
    deploy_json = json.dumps(deploy_apps)

    github_output = os.environ.get("GITHUB_OUTPUT")
    if github_output:
        with open(github_output, "a") as fh:
            fh.write(f"all-apps={all_json}\n")
            fh.write(f"deploy-apps={deploy_json}\n")

    print(f"all-apps={all_json}")
    print(f"deploy-apps={deploy_json}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
