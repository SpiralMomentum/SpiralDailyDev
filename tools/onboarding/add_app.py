#!/usr/bin/env python3
"""신규 Flutter 앱을 CI/CD와 스토어에 온보딩한다 (앱당 1회).

    python3 tools/onboarding/add_app.py --app my_app --display-name "My App" [--dry-run]
    python3 tools/onboarding/add_app.py --app my_app --display-name "My App" --skip-store --skip-signing

단계: release.yaml 항목 -> signing -> 메타데이터 템플릿 -> build.gradle 패치 -> 스토어 등록
기본값(패키지 접두사, developer ID, 경로 등)은 release.yaml의 org/paths/defaults에서 읽는다.
"""

from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, List, Optional, Sequence, Tuple

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from common.config import CONFIG_PATH, REPO_ROOT, Config, default, load_config, org, path_for
from common.effects import Effects, done, effects_for, fail
from common.names import app_name_error
from onboarding.gradle_patch import patch_gradle
from onboarding.project_ids import AppIds, detect_ids, listing_mismatches, resolve_ids
from onboarding.release_entry import add_release_entry, new_entry
from onboarding.signing import setup_signing
from store.app_store import register_app_store
from store.listing.templates import write_templates
from store.play_store import register_play_store


@dataclass(frozen=True)
class Plan:
    app: str
    display_name: str
    android_id: str
    ios_bundle_id: str
    play_developer_id: Optional[str]
    backend: str
    exclude_from_release: bool
    coverage_threshold: int
    skip: frozenset


def make_plan(cfg: Config, args: argparse.Namespace, ids: AppIds) -> Plan:
    return Plan(
        app=args.app,
        display_name=args.display_name,
        android_id=ids.android,
        ios_bundle_id=ids.ios,
        play_developer_id=args.play_developer_id or str(org(cfg, "playDeveloperId")),
        backend=args.backend or default(cfg, "registrationBackend"),
        exclude_from_release=args.exclude_from_release,
        coverage_threshold=args.coverage_threshold or default(cfg, "coverageThreshold"),
        skip=frozenset(n for n in ("signing", "gradle", "store") if getattr(args, f"skip_{n}")),
    )


def precondition_error(repo_root: Path, app: str) -> Optional[str]:
    if not (repo_root / "apps" / app).exists():
        return f"apps/{app}/ 디렉토리가 없습니다. 먼저 Flutter 프로젝트를 생성하세요."
    if not (repo_root / "apps" / app / "pubspec.yaml").exists():
        return f"apps/{app}/pubspec.yaml이 없습니다."
    return None


def summary(cfg: Config, plan: Plan, problems: Sequence[Tuple[str, str]], has_listing: bool) -> List[str]:
    """problems: (단계, 실패 이유). 하나라도 있으면 '완료'라고 쓰지 않는다."""
    title = "온보딩 완료" if not problems else f"온보딩 미완료 — {len(problems)}개 단계 실패"
    steps = [
        *([] if has_listing else [f"{path_for(cfg, 'storeListing', plan.app)} 작성 (스키마: tools/store/listing/schema.yaml)"]),
        f"python3 tools/store/listing/generate_metadata.py --app {plan.app}",
        f"{path_for(cfg, 'storeMetadata', plan.app)}/*.yaml 채우기",
        f"Firebase 사용 시 GitHub Secret GOOGLE_SERVICES_JSON_{plan.app.upper()} 등록",
        "PR을 올려 CI 동작 확인",
    ]
    return [
        "=" * 60,
        f"{title}: {plan.display_name} ({plan.app})",
        "=" * 60,
        f"  Android App ID:  {plan.android_id}",
        f"  iOS Bundle ID:   {plan.ios_bundle_id}",
        *([f"  스킵된 단계:     {', '.join(sorted(plan.skip))}"] if plan.skip else []),
        *(["", "--- 실패한 단계 ---"] + [f"  {step}: {reason}" for step, reason in problems] if problems else []),
        "",
        "--- 다음 단계 ---",
        *(f"  {i}. {text}" for i, text in enumerate(steps, 1)),
    ]


def run_step(effects: Effects, title: str, skipped: bool, action: Callable[[], Optional[str]]) -> Optional[str]:
    """실패 이유 또는 None. 한 단계 실패가 나머지 단계를 막지 않도록 예외도 이유로 바꾼다."""
    effects.log(f"\n[{title}]")
    if skipped:
        effects.log("  건너뜀")
        return None
    try:
        return action()
    except Exception as e:
        effects.log(f"경고: {title} 중 오류: {type(e).__name__}: {e}")
        return f"{type(e).__name__}: {e}"


def onboard(effects: Effects, cfg: Config, plan: Plan, repo_root: Path = REPO_ROOT) -> List[Tuple[str, str]]:
    """실패한 (단계, 이유) 목록을 돌려준다."""
    entry = new_entry(cfg, plan.app, plan.display_name, plan.android_id, plan.ios_bundle_id,
                      plan.exclude_from_release, plan.coverage_threshold)
    cfg, message = add_release_entry(effects, repo_root / CONFIG_PATH.name, cfg, plan.app, entry)
    effects.log("\n[release.yaml]")
    done(effects, f"  {message}")

    steps = [
        ("Android signing", "signing" in plan.skip,
         lambda: setup_signing(effects, cfg, repo_root, plan.app)),
        ("메타데이터 템플릿", False,
         lambda: write_templates(effects, cfg, plan.app, plan.display_name, repo_root)),
        ("build.gradle 패치", "gradle" in plan.skip,
         lambda: patch_gradle(effects, cfg, repo_root, plan.app)),
        ("App Store 등록", "store" in plan.skip,
         lambda: register_app_store(effects, repo_root, plan.ios_bundle_id, plan.display_name)),
        ("Play Store 등록", "store" in plan.skip,
         lambda: register_play_store(effects, cfg, repo_root, plan.app, plan.android_id,
                                     plan.play_developer_id, plan.backend)),
    ]
    problems = [(title, reason) for title, skipped, action in steps
                for reason in [run_step(effects, title, skipped, action)] if reason]

    has_listing = effects.exists(repo_root / path_for(cfg, "storeListing", plan.app))
    for line in summary(cfg, plan, problems, has_listing):
        effects.log(line)
    return problems


def parse_args(argv: Optional[List[str]]) -> argparse.Namespace:
    p = argparse.ArgumentParser(description="신규 Flutter 앱 온보딩")
    p.add_argument("--app", required=True, help="snake_case 앱 이름")
    p.add_argument("--display-name", required=True)
    p.add_argument("--app-id", help="Android application ID (기본값: build.gradle의 applicationId)")
    p.add_argument("--ios-bundle-id", help="iOS bundle ID (기본값: project.pbxproj의 Runner bundle ID)")
    p.add_argument("--play-developer-id", help="기본값: release.yaml org.playDeveloperId")
    p.add_argument("--backend", help="Play Console 자동화 백엔드 (기본값: defaults.registrationBackend)")
    p.add_argument("--skip-store", action="store_true")
    p.add_argument("--skip-signing", action="store_true")
    p.add_argument("--skip-gradle", action="store_true")
    p.add_argument("--exclude-from-release", action="store_true")
    p.add_argument("--coverage-threshold", type=int, help="기본값: defaults.coverageThreshold")
    p.add_argument("--dry-run", action="store_true")
    return p.parse_args(argv)


def main(argv: Optional[List[str]] = None) -> int:
    args = parse_args(argv)
    error = app_name_error(args.app) or precondition_error(REPO_ROOT, args.app)
    if error:
        return fail(error)

    cfg = load_config()
    effects = effects_for(args.dry_run)
    ids = resolve_ids(cfg, args.app, *detect_ids(effects, cfg, REPO_ROOT, args.app), args.app_id, args.ios_bundle_id)
    conflicts = listing_mismatches(effects, cfg, REPO_ROOT, args.app, ids)
    if conflicts:
        return fail("ID 불일치 — 하나로 맞춘 뒤 다시 실행하세요:\n  " + "\n  ".join(conflicts))

    effects.log(f"온보딩 시작: {args.display_name} ({args.app})" + ("  [dry-run]" if args.dry_run else ""))
    problems = onboard(effects, cfg, make_plan(cfg, args, ids))
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
