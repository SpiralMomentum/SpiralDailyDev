#!/usr/bin/env python3
"""빌드/테스트/배포 통합 인터페이스.

CI와 로컬 모두 이 스크립트를 통해 빌드/테스트/배포한다.

사용법:
    python3 tools/pipeline/pipeline.py prepare --app daily_memo
    python3 tools/pipeline/pipeline.py test    --app daily_memo
    python3 tools/pipeline/pipeline.py build   --app daily_memo --platform android
    python3 tools/pipeline/pipeline.py deploy  --app daily_memo --platform android --target production
"""

from __future__ import annotations

import argparse
import shlex
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict

import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent.parent

sys.path.insert(0, str(Path(__file__).resolve().parent / "steps"))

from prepare_build import prepare


def load_config(config_path: Path | None = None) -> Dict[str, Any]:
    path = config_path or (REPO_ROOT / "release.yaml")
    with path.open("r", encoding="utf-8") as fh:
        return yaml.safe_load(fh)


def get_app_config(config: Dict[str, Any], app_name: str) -> Dict[str, Any]:
    apps = config.get("apps", {})
    if app_name not in apps:
        print(f"오류: '{app_name}'은 release.yaml에 등록되지 않은 앱입니다", file=sys.stderr)
        sys.exit(1)
    return apps[app_name]


def run(command: list[str], *, cwd: Path | None = None, dry_run: bool = False) -> None:
    printable = " ".join(shlex.quote(str(c)) for c in command)
    location = f"  (cwd: {cwd})" if cwd else ""
    if dry_run:
        print(f"  [dry-run] {printable}{location}")
        return
    print(f"  -> {printable}{location}")
    subprocess.run(command, cwd=cwd, check=True)


# ── 서브커맨드 ─────────────────────────────────────────

def cmd_prepare(args: argparse.Namespace) -> int:
    config = load_config()
    app_config = get_app_config(config, args.app)
    print(f"[prepare] {args.app}: gitignored 파일 생성")
    prepare(args.app, app_config, repo_root=REPO_ROOT)
    return 0


def cmd_test(args: argparse.Namespace) -> int:
    config = load_config()
    app_config = get_app_config(config, args.app)
    project_path = REPO_ROOT / app_config.get("projectPath", f"apps/{args.app}")

    print(f"[test] {args.app}: 빌드 준비")
    prepare(args.app, app_config, repo_root=REPO_ROOT)

    print(f"[test] {args.app}: flutter test 실행")
    test_cmd = ["flutter", "test"]
    if args.coverage:
        test_cmd.append("--coverage")
    run(test_cmd, cwd=project_path, dry_run=args.dry_run)
    return 0


def cmd_build(args: argparse.Namespace) -> int:
    config = load_config()
    app_config = get_app_config(config, args.app)
    project_path = REPO_ROOT / app_config.get("projectPath", f"apps/{args.app}")

    print(f"[build] {args.app}: 빌드 준비")
    prepare(args.app, app_config, repo_root=REPO_ROOT)

    build_config = app_config.get("build", {}).get(args.platform, {})
    command = build_config.get("command")
    if not command:
        print(f"오류: {args.app}의 {args.platform} 빌드 설정을 찾을 수 없습니다", file=sys.stderr)
        return 1

    print(f"[build] {args.app}: {args.platform} 빌드")
    run(command, cwd=project_path, dry_run=args.dry_run)
    return 0


def cmd_deploy(args: argparse.Namespace) -> int:
    config = load_config()
    pipeline_config = config.get("pipeline", {})
    app_config = get_app_config(config, args.app)

    print(f"[deploy] {args.app}: 빌드 준비")
    prepare(args.app, app_config, repo_root=REPO_ROOT)

    fastlane_bin = pipeline_config.get("fastlaneBinary", "bundle exec fastlane")
    fastlane_parts = shlex.split(fastlane_bin)

    # 플랫폼과 타겟에 따라 Fastlane 레인 결정
    lane = _resolve_lane(args.platform, args.target)

    command = [*fastlane_parts, *lane.split(), f"app:{args.app}"]

    print(f"[deploy] {args.app}: {args.platform} {args.target} 배포")
    run(command, cwd=REPO_ROOT, dry_run=args.dry_run)
    return 0


def _resolve_lane(platform: str, target: str) -> str:
    """플랫폼과 타겟으로 Fastlane 레인 이름을 결정한다."""
    lanes = {
        ("android", "internal"): "android deploy_internal",
        ("android", "production"): "android deploy_production",
        ("ios", "testflight"): "ios deploy_testflight",
        ("ios", "appstore"): "ios deploy_appstore",
    }
    lane = lanes.get((platform, target))
    if not lane:
        print(f"오류: {platform}/{target} 조합의 레인을 찾을 수 없습니다", file=sys.stderr)
        sys.exit(1)
    return lane


# ── CLI ────────────────────────────────────────────────

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="빌드/테스트/배포 통합 인터페이스",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    # prepare
    p_prepare = subparsers.add_parser("prepare", help="빌드 전 준비 (gitignored 파일 생성)")
    p_prepare.add_argument("--app", required=True)
    p_prepare.set_defaults(func=cmd_prepare)

    # test
    p_test = subparsers.add_parser("test", help="테스트 실행")
    p_test.add_argument("--app", required=True)
    p_test.add_argument("--coverage", action="store_true", help="커버리지 수집")
    p_test.add_argument("--dry-run", action="store_true")
    p_test.set_defaults(func=cmd_test)

    # build
    p_build = subparsers.add_parser("build", help="앱 빌드")
    p_build.add_argument("--app", required=True)
    p_build.add_argument("--platform", required=True, choices=["android", "ios"])
    p_build.add_argument("--dry-run", action="store_true")
    p_build.set_defaults(func=cmd_build)

    # deploy
    p_deploy = subparsers.add_parser("deploy", help="앱 빌드 + 스토어 배포")
    p_deploy.add_argument("--app", required=True)
    p_deploy.add_argument("--platform", required=True, choices=["android", "ios"])
    p_deploy.add_argument("--target", required=True,
                          choices=["internal", "production", "testflight", "appstore"])
    p_deploy.add_argument("--dry-run", action="store_true")
    p_deploy.set_defaults(func=cmd_deploy)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
