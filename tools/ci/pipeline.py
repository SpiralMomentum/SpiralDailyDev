#!/usr/bin/env python3
"""빌드/테스트/배포 통합 인터페이스. CI와 로컬 모두 이 스크립트를 쓴다.

사용법:
    python3 tools/ci/pipeline.py prepare --app daily_memo
    python3 tools/ci/pipeline.py test    --app daily_memo [--coverage]
    python3 tools/ci/pipeline.py build   --app daily_memo --platform android
    python3 tools/ci/pipeline.py deploy  --app daily_memo --platform android --target production
"""

from __future__ import annotations

import argparse
import shlex
import sys
from pathlib import Path
from typing import List, Optional

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from ci.prepare_build import prepare
from common.config import REPO_ROOT, Config, app_config, load_config, project_path
from common.effects import Effects, effects_for, fail

LANES = {
    ("android", "internal"): "android deploy_internal",
    ("android", "production"): "android deploy_production",
    ("ios", "testflight"): "ios deploy_testflight",
    ("ios", "appstore"): "ios deploy_appstore",
}


def test_command(coverage: bool) -> List[str]:
    return ["flutter", "test", *(["--coverage"] if coverage else [])]


def build_command(cfg: Config, app: str, platform: str) -> Optional[List[str]]:
    return ((app_config(cfg, app) or {}).get("build") or {}).get(platform, {}).get("command")


def deploy_command(cfg: Config, app: str, platform: str, target: str) -> Optional[List[str]]:
    lane = LANES.get((platform, target))
    if not lane:
        return None
    fastlane = shlex.split((cfg.get("pipeline") or {}).get("fastlaneBinary", "bundle exec fastlane"))
    return [*fastlane, *lane.split(), f"app:{app}"]


def _ok(effects: Effects, cmd: List[str], cwd: Path) -> int:
    return 0 if effects.run(cmd, cwd=cwd).ok else 1


def cmd_prepare(effects: Effects, cfg: Config, args: argparse.Namespace) -> int:
    effects.log(f"[prepare] {args.app}: gitignored 파일 생성")
    prepare(effects, cfg, args.app)
    return 0


def cmd_test(effects: Effects, cfg: Config, args: argparse.Namespace) -> int:
    prepare(effects, cfg, args.app)
    effects.log(f"[test] {args.app}: flutter test 실행")
    return _ok(effects, test_command(args.coverage), REPO_ROOT / project_path(cfg, args.app))


def cmd_build(effects: Effects, cfg: Config, args: argparse.Namespace) -> int:
    command = build_command(cfg, args.app, args.platform)
    if not command:
        return fail(f"{args.app}의 {args.platform} 빌드 설정을 찾을 수 없습니다")
    prepare(effects, cfg, args.app)
    effects.log(f"[build] {args.app}: {args.platform} 빌드")
    return _ok(effects, command, REPO_ROOT / project_path(cfg, args.app))


def cmd_deploy(effects: Effects, cfg: Config, args: argparse.Namespace) -> int:
    command = deploy_command(cfg, args.app, args.platform, args.target)
    if not command:
        return fail(f"{args.platform}/{args.target} 조합의 레인을 찾을 수 없습니다")
    prepare(effects, cfg, args.app)
    effects.log(f"[deploy] {args.app}: {args.platform} {args.target} 배포")
    return _ok(effects, command, REPO_ROOT)


def parse_args(argv: Optional[List[str]]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="빌드/테스트/배포 통합 인터페이스")
    sub = parser.add_subparsers(dest="command", required=True)

    def add(name: str, func, help_text: str, platform: bool = False) -> argparse.ArgumentParser:
        p = sub.add_parser(name, help=help_text)
        p.add_argument("--app", required=True)
        p.add_argument("--dry-run", action="store_true")
        if platform:
            p.add_argument("--platform", required=True, choices=["android", "ios"])
        p.set_defaults(func=func)
        return p

    add("prepare", cmd_prepare, "빌드 전 준비 (gitignored 파일 생성)")
    add("test", cmd_test, "테스트 실행").add_argument("--coverage", action="store_true")
    add("build", cmd_build, "앱 빌드", platform=True)
    add("deploy", cmd_deploy, "앱 빌드 + 스토어 배포", platform=True).add_argument(
        "--target", required=True, choices=["internal", "production", "testflight", "appstore"]
    )
    return parser.parse_args(argv)


def main(argv: Optional[List[str]] = None) -> int:
    args = parse_args(argv)
    cfg = load_config()
    if not app_config(cfg, args.app):
        return fail(f"'{args.app}'은 release.yaml에 등록되지 않은 앱입니다")
    return args.func(effects_for(args.dry_run), cfg, args)


if __name__ == "__main__":
    sys.exit(main())
