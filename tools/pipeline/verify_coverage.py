#!/usr/bin/env python3
"""release.yaml의 ci.coverageThreshold + coverage/lcov.info로 커버리지를 검증한다.

사용법 (앱 디렉토리에서 실행):
    python3 tools/pipeline/verify_coverage.py --app daily_memo

종료 코드:
    0: 임계값 충족
    1: 임계값 미달 또는 커버리지 파일 없음
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent.parent

DEFAULT_THRESHOLD = 50


def parse_lcov(lcov_path: Path) -> tuple[int, int]:
    """lcov.info에서 총 라인 수와 커버된 라인 수를 반환한다."""
    total = 0
    covered = 0
    with lcov_path.open("r", encoding="utf-8") as fh:
        for line in fh:
            if line.startswith("DA:"):
                total += 1
                # DA:line_number,execution_count
                parts = line.strip().split(",")
                if len(parts) >= 2 and parts[1] != "0":
                    covered += 1
    return total, covered


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="커버리지 검증")
    parser.add_argument("--app", required=True, help="앱 이름")
    args = parser.parse_args(argv)

    # release.yaml에서 임계값 읽기
    config_path = REPO_ROOT / "release.yaml"
    with config_path.open("r", encoding="utf-8") as fh:
        config = yaml.safe_load(fh)

    app_config = config.get("apps", {}).get(args.app)
    if not app_config:
        print(f"오류: '{args.app}'을 release.yaml에서 찾을 수 없습니다", file=sys.stderr)
        return 1

    ci = app_config.get("ci") or {}
    threshold = ci.get("coverageThreshold", DEFAULT_THRESHOLD)

    # lcov.info 찾기 (현재 디렉토리 기준)
    lcov_path = Path("coverage/lcov.info")
    if not lcov_path.exists():
        # 앱 디렉토리 기준으로도 시도
        project_path = REPO_ROOT / app_config.get("projectPath", f"apps/{args.app}")
        lcov_path = project_path / "coverage" / "lcov.info"

    if not lcov_path.exists():
        print("오류: coverage/lcov.info를 찾을 수 없습니다", file=sys.stderr)
        return 1

    total, covered = parse_lcov(lcov_path)

    if total == 0:
        print("오류: lcov.info에 커버리지 데이터가 없습니다", file=sys.stderr)
        return 1

    percent = covered * 100 // total
    print(f"Coverage: {covered} / {total} lines ({percent}%)")
    print(f"Threshold for {args.app}: {threshold}%")

    if percent < threshold:
        print(f"오류: 커버리지 {percent}%가 임계값 {threshold}% 미만입니다", file=sys.stderr)
        return 1

    print(f"커버리지 {percent}%가 임계값 {threshold}%를 충족합니다")
    return 0


if __name__ == "__main__":
    sys.exit(main())
