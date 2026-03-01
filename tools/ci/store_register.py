"""스토어 신규 등록을 처리한다.

App Store: fastlane produce + match로 자동화
Play Store: 수동 생성 가이드 출력 (API 미지원)
"""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

from name_utils import snake_to_camel


def register_app_store(
    app_name: str,
    ios_bundle_id: str | None = None,
    *,
    dry_run: bool = True,
) -> None:
    """App Store Connect에 앱을 등록하고 match 프로비저닝 프로필을 생성한다."""
    bundle_id = ios_bundle_id or f"com.spiraldev.{snake_to_camel(app_name)}"

    print("\n--- App Store Connect 등록 ---")

    if not shutil.which("bundle"):
        print("경고: bundler를 찾을 수 없습니다. `gem install bundler && bundle install`을 실행하세요.")
        return

    # 1) fastlane produce로 앱 생성
    produce_cmd = [
        "bundle", "exec", "fastlane", "produce", "create",
        "-u", "spiraldailydev@gmail.com",
        "-a", bundle_id,
        "--skip_itc",
    ]

    if dry_run:
        print(f"[dry-run] {' '.join(produce_cmd)}")
    else:
        print(f"실행: {' '.join(produce_cmd)}")
        try:
            subprocess.run(produce_cmd, check=True)
            print("App Store Connect에 앱을 등록했습니다")
        except subprocess.CalledProcessError as e:
            print(f"경고: App Store Connect 등록 실패: {e}")
            print("환경변수를 확인하세요: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_CONTENT")

    # 2) match로 프로비저닝 프로필 생성
    match_cmd = [
        "bundle", "exec", "fastlane", "match", "appstore",
        "-a", bundle_id,
    ]

    if dry_run:
        print(f"[dry-run] {' '.join(match_cmd)}")
    else:
        print(f"실행: {' '.join(match_cmd)}")
        try:
            subprocess.run(match_cmd, check=True)
            print("프로비저닝 프로필을 생성했습니다")
        except subprocess.CalledProcessError as e:
            print(f"경고: match 실패: {e}")
            print("환경변수를 확인하세요: MATCH_PASSWORD")


def print_play_store_guide(
    app_name: str,
    app_id: str | None = None,
) -> None:
    """Play Store 수동 등록 가이드를 출력한다."""
    package_name = app_id or f"com.spiraldev.{app_name}"

    print("\n--- Google Play Store 등록 가이드 ---")
    print("Google Play Developer API는 신규 앱 생성을 지원하지 않습니다.")
    print("아래 단계를 수동으로 진행하세요:\n")
    print("1. Play Console에서 앱 생성:")
    print("   https://play.google.com/console/developers")
    print(f"\n2. 패키지 이름 입력: {package_name}")
    print(f"\n3. 생성 후 첫 internal build 업로드:")
    print(f"   cd apps/{app_name}")
    print(f"   flutter build appbundle --release")
    print(f"   bundle exec fastlane android deploy_internal app:{app_name}")
    print(f"\n4. GitHub Secrets에 서비스 계정 JSON이 등록되어 있는지 확인:")
    print(f"   GOOGLE_PLAY_SERVICE_ACCOUNT_JSON")


def register_stores(
    app_name: str,
    *,
    app_id: str | None = None,
    ios_bundle_id: str | None = None,
    dry_run: bool = True,
) -> None:
    """App Store 등록 + Play Store 가이드를 실행한다."""
    register_app_store(app_name, ios_bundle_id, dry_run=dry_run)
    print_play_store_guide(app_name, app_id)
