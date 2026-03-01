#!/usr/bin/env python3
"""CI/CD 파이프라인에 새 Flutter 앱을 등록하는 도구.

사용법:
    python tools/ci/register_app.py --app my_app --display-name "My App"
    python tools/ci/register_app.py --app my_app --display-name "My App" --dry-run
    python tools/ci/register_app.py --app my_app --display-name "My App" --skip-store --skip-signing
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent

# 같은 디렉토리의 모듈을 import할 수 있도록 sys.path에 추가
sys.path.insert(0, str(Path(__file__).resolve().parent))

from name_utils import snake_to_camel, validate_app_name
from config_editor import add_app_to_release_config
from workflow_editor import add_to_all_workflows
from signing_setup import setup_signing
from metadata_setup import setup_all_metadata
from gradle_patcher import patch_gradle
from store_register import register_stores


def validate_preconditions(app_name: str) -> None:
    """앱 등록 전 사전 조건을 검증한다."""
    app_dir = REPO_ROOT / "apps" / app_name
    if not app_dir.exists():
        raise FileNotFoundError(
            f"apps/{app_name}/ 디렉토리가 존재하지 않습니다. "
            f"먼저 Flutter 프로젝트를 생성하세요."
        )

    pubspec = app_dir / "pubspec.yaml"
    if not pubspec.exists():
        raise FileNotFoundError(
            f"apps/{app_name}/pubspec.yaml이 존재하지 않습니다. "
            f"올바른 Flutter 프로젝트인지 확인하세요."
        )


def print_summary(
    app_name: str,
    display_name: str,
    app_id: str,
    ios_bundle_id: str,
    *,
    skipped: list[str],
) -> None:
    """완료 요약을 출력한다."""
    print("\n" + "=" * 60)
    print(f"CI/CD 등록 완료: {display_name} ({app_name})")
    print("=" * 60)
    print(f"  Android App ID:  {app_id}")
    print(f"  iOS Bundle ID:   {ios_bundle_id}")
    if skipped:
        print(f"  스킵된 단계:     {', '.join(skipped)}")

    app_upper = app_name.upper()
    print("\n--- GitHub Secrets 등록 체크리스트 ---")
    print(f"  [ ] ANDROID_KEYSTORE_{app_upper}_BASE64")
    print(f"  [ ] ANDROID_STORE_PASSWORD_{app_upper}")
    print(f"  [ ] ANDROID_KEY_PASSWORD_{app_upper}")
    print(f"  [ ] ANDROID_KEY_ALIAS_{app_upper}")
    print(f"  [ ] GOOGLE_SERVICES_JSON_{app_upper} (Firebase 사용 시)")
    print("\n--- 다음 단계 ---")
    print(f"  1. store_metadata/{app_name}/android.yaml 내용 채우기")
    print(f"  2. store_metadata/{app_name}/ios.yaml 내용 채우기")
    print(f"  3. fastlane/metadata/{app_name}/en-US/ 내용 채우기")
    print(f"  4. fastlane/metadata/{app_name}/ko/ 내용 채우기")
    print(f"  5. GitHub Secrets 등록")
    print(f"  6. PR을 올려서 CI 파이프라인 동작 확인")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="CI/CD 파이프라인에 새 Flutter 앱을 등록합니다",
    )
    parser.add_argument(
        "--app", required=True,
        help="앱 이름 (snake_case, 예: my_new_app)",
    )
    parser.add_argument(
        "--display-name", required=True,
        help="앱 표시 이름 (예: \"My New App\")",
    )
    parser.add_argument(
        "--app-id",
        help="Android application ID (기본값: com.spiraldev.{app_name})",
    )
    parser.add_argument(
        "--ios-bundle-id",
        help="iOS bundle ID (기본값: com.spiraldev.{camelCase(app_name)})",
    )
    parser.add_argument(
        "--skip-store", action="store_true",
        help="스토어 등록 건너뛰기",
    )
    parser.add_argument(
        "--skip-signing", action="store_true",
        help="keystore/match 생성 건너뛰기",
    )
    parser.add_argument(
        "--skip-gradle", action="store_true",
        help="build.gradle 패치 건너뛰기",
    )
    parser.add_argument(
        "--exclude-from-release", action="store_true",
        help="release-all.yaml 배포 matrix에서 제외",
    )
    parser.add_argument(
        "--coverage-threshold", type=int, default=50,
        help="CI 커버리지 임계값 (기본값: 50)",
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="실제 변경 없이 예정 작업만 출력",
    )

    args = parser.parse_args(argv)

    app_name: str = args.app
    display_name: str = args.display_name
    app_id = args.app_id or f"com.spiraldev.{app_name}"
    ios_bundle_id = args.ios_bundle_id or f"com.spiraldev.{snake_to_camel(app_name)}"
    dry_run: bool = args.dry_run
    skipped: list[str] = []

    # 0. 앱 이름 유효성 검증
    try:
        validate_app_name(app_name)
    except ValueError as e:
        print(f"오류: {e}", file=sys.stderr)
        return 1

    # 1. 사전 조건 검증
    try:
        validate_preconditions(app_name)
    except FileNotFoundError as e:
        print(f"오류: {e}", file=sys.stderr)
        return 1

    print("=" * 60)
    print(f"CI/CD 등록 시작: {display_name} ({app_name})")
    if dry_run:
        print("  (dry-run 모드: 실제 변경 없음)")
    print("=" * 60)

    # 2. release.yaml에 앱 추가
    print("\n[1/6] release.yaml 편집")
    try:
        add_app_to_release_config(
            REPO_ROOT / "release.yaml",
            app_name=app_name,
            display_name=display_name,
            app_id=app_id,
            ios_bundle_id=ios_bundle_id,
            dry_run=dry_run,
        )
    except ValueError as e:
        print(f"경고: {e}")

    # 3. 워크플로우 파일에 앱 추가
    print("\n[2/6] GitHub Actions 워크플로우 편집")
    try:
        add_to_all_workflows(
            REPO_ROOT / ".github" / "workflows",
            app_name,
            exclude_from_release=args.exclude_from_release,
            coverage_threshold=args.coverage_threshold,
            dry_run=dry_run,
        )
    except Exception as e:
        print(f"경고: 워크플로우 편집 중 오류: {e}")

    # 4. signing 설정
    print("\n[3/6] Android signing 설정")
    if args.skip_signing:
        print("  --skip-signing: 건너뜁니다")
        skipped.append("signing")
    else:
        try:
            setup_signing(REPO_ROOT, app_name, dry_run=dry_run)
        except Exception as e:
            print(f"경고: signing 설정 중 오류: {e}")

    # 5. 메타데이터 생성
    print("\n[4/6] 메타데이터 템플릿 생성")
    try:
        setup_all_metadata(REPO_ROOT, app_name, display_name, dry_run=dry_run)
    except Exception as e:
        print(f"경고: 메타데이터 생성 중 오류: {e}")

    # 6. build.gradle 패치
    print("\n[5/6] build.gradle signing config 패치")
    if args.skip_gradle:
        print("  --skip-gradle: 건너뜁니다")
        skipped.append("gradle")
    else:
        try:
            patch_gradle(REPO_ROOT, app_name, dry_run=dry_run)
        except Exception as e:
            print(f"경고: build.gradle 패치 중 오류: {e}")

    # 7. 스토어 등록
    print("\n[6/6] 스토어 등록")
    if args.skip_store:
        print("  --skip-store: 건너뜁니다")
        skipped.append("store")
    else:
        try:
            register_stores(
                app_name,
                app_id=app_id,
                ios_bundle_id=ios_bundle_id,
                dry_run=dry_run,
            )
        except Exception as e:
            print(f"경고: 스토어 등록 중 오류: {e}")

    # 8. 완료 요약
    print_summary(app_name, display_name, app_id, ios_bundle_id, skipped=skipped)

    return 0


if __name__ == "__main__":
    sys.exit(main())
