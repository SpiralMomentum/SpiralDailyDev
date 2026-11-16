#!/usr/bin/env python3
"""release.yaml ci.coverageThreshold와 coverage/lcov.info로 커버리지를 검증한다.

사용법 (앱 디렉토리에서 실행):
    python3 tools/ci/verify_coverage.py --app daily_memo
종료 코드: 0 충족, 1 미달 또는 커버리지 파일 없음
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Iterable, List, Optional, Tuple

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from common.config import REPO_ROOT, Config, app_config, default, load_config, project_path
from common.effects import fail


def parse_lcov(lines: Iterable[str]) -> Tuple[int, int]:
    """(총 라인 수, 커버된 라인 수). DA:line_number,execution_count"""
    hits = [line.strip().split(",") for line in lines if line.startswith("DA:")]
    return len(hits), sum(1 for parts in hits if len(parts) >= 2 and parts[1] != "0")


def threshold_for(cfg: Config, app: str) -> int:
    return ((app_config(cfg, app) or {}).get("ci") or {}).get("coverageThreshold", default(cfg, "coverageThreshold"))


def lcov_candidates(cfg: Config, app: str) -> List[Path]:
    return [Path("coverage/lcov.info"), REPO_ROOT / project_path(cfg, app) / "coverage" / "lcov.info"]


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="커버리지 검증")
    parser.add_argument("--app", required=True)
    args = parser.parse_args(argv)

    cfg = load_config()
    if not app_config(cfg, args.app):
        return fail(f"'{args.app}'을 release.yaml에서 찾을 수 없습니다")

    lcov = next((p for p in lcov_candidates(cfg, args.app) if p.exists()), None)
    if not lcov:
        return fail("coverage/lcov.info를 찾을 수 없습니다")

    total, covered = parse_lcov(lcov.read_text(encoding="utf-8").splitlines())
    if total == 0:
        return fail("lcov.info에 커버리지 데이터가 없습니다")

    threshold = threshold_for(cfg, args.app)
    percent = covered * 100 // total
    print(f"Coverage: {covered} / {total} lines ({percent}%)")
    print(f"Threshold for {args.app}: {threshold}%")
    if percent < threshold:
        return fail(f"커버리지 {percent}%가 임계값 {threshold}% 미만입니다")
    print(f"커버리지 {percent}%가 임계값 {threshold}%를 충족합니다")
    return 0


if __name__ == "__main__":
    sys.exit(main())
