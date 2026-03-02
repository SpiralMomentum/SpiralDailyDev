"""스토어 신규 등록을 처리한다.

App Store: Spaceship ConnectAPI로 Bundle ID 등록 + 앱 생성 안내
Play Store: 수동 생성 가이드 출력 (API 미지원)
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

from name_utils import snake_to_camel


def _find_api_key_config() -> dict[str, str] | None:
    """ASC API Key 설정을 환경변수 또는 .p8 파일에서 찾는다."""
    key_id = os.environ.get("ASC_KEY_ID")
    issuer_id = os.environ.get("ASC_ISSUER_ID")

    if not key_id or not issuer_id:
        return None

    # key_filepath 우선, 없으면 key_content
    key_filepath = os.environ.get("ASC_KEY_FILEPATH")
    key_content = os.environ.get("ASC_KEY_CONTENT")

    if key_filepath and Path(key_filepath).exists():
        return {
            "key_id": key_id,
            "issuer_id": issuer_id,
            "key_filepath": key_filepath,
        }
    elif key_content:
        return {
            "key_id": key_id,
            "issuer_id": issuer_id,
            "key_content": key_content,
        }
    return None


def _write_api_key_json(config: dict[str, str]) -> str:
    """Fastlane용 api_key.json 임시 파일을 생성한다."""
    if "key_filepath" in config:
        key = Path(config["key_filepath"]).read_text()
    else:
        key = config["key_content"]

    data = {
        "key_id": config["key_id"],
        "issuer_id": config["issuer_id"],
        "key": key,
        "in_house": False,
    }
    fd, path = tempfile.mkstemp(suffix=".json", prefix="asc_api_key_")
    with os.fdopen(fd, "w") as f:
        json.dump(data, f)
    return path


def _run_fastlane_ruby(script: str, *, cwd: Path | None = None) -> tuple[bool, str]:
    """Fastlane Ruby 스크립트를 인라인 실행한다."""
    cmd = ["bundle", "exec", "ruby", "-e", script]
    try:
        result = subprocess.run(
            cmd, capture_output=True, text=True, check=True, cwd=cwd,
        )
        return True, result.stdout
    except subprocess.CalledProcessError as e:
        return False, e.stderr


def register_app_store(
    app_name: str,
    display_name: str,
    ios_bundle_id: str | None = None,
    *,
    repo_root: Path | None = None,
    dry_run: bool = True,
) -> None:
    """Apple Developer Portal에 Bundle ID를 등록하고 App Store Connect 앱 생성을 안내한다."""
    bundle_id = ios_bundle_id or f"com.spiraldev.{snake_to_camel(app_name)}"

    print("\n--- App Store 등록 ---")

    api_config = _find_api_key_config()
    if not api_config:
        print("환경변수 미설정. 아래 값을 export하세요:")
        print("  ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_FILEPATH (또는 ASC_KEY_CONTENT)")
        return

    if not shutil.which("bundle"):
        print("경고: bundler를 찾을 수 없습니다.")
        return

    api_key_path = _write_api_key_json(api_config)
    try:
        _register_bundle_id_and_app(bundle_id, display_name, api_key_path, repo_root=repo_root, dry_run=dry_run)
        _run_match(bundle_id, api_key_path, dry_run=dry_run)
    finally:
        os.unlink(api_key_path)


def _register_bundle_id_and_app(
    bundle_id: str,
    display_name: str,
    api_key_path: str,
    *,
    repo_root: Path | None = None,
    dry_run: bool = True,
) -> None:
    """Spaceship ConnectAPI로 Bundle ID 등록 + App Store Connect 앱 생성을 시도한다."""
    # Ruby 스크립트로 Spaceship API 직접 호출
    ruby_script = f'''
require "spaceship"
require "json"

api_key_data = JSON.parse(File.read("{api_key_path}"))
key = Spaceship::ConnectAPI::Token.create(
  key_id: api_key_data["key_id"],
  issuer_id: api_key_data["issuer_id"],
  key: api_key_data["key"],
)
Spaceship::ConnectAPI.token = key

bundle_id = "{bundle_id}"
app_name = "{display_name}"

# 1. Bundle ID 등록
existing = Spaceship::ConnectAPI::BundleId.find(bundle_id)
if existing
  puts "BUNDLE_ID_EXISTS"
else
  Spaceship::ConnectAPI::BundleId.create(
    name: app_name,
    identifier: bundle_id,
    platform: Spaceship::ConnectAPI::BundleIdPlatform::IOS,
  )
  puts "BUNDLE_ID_CREATED"
end

# 2. App Store Connect 앱 확인
app = Spaceship::ConnectAPI::App.find(bundle_id)
if app
  puts "APP_EXISTS"
else
  puts "APP_NOT_FOUND"
end
'''

    if dry_run:
        print(f"[dry-run] Bundle ID '{bundle_id}' 등록 예정")
        print(f"[dry-run] App Store Connect 앱 확인 예정")
        return

    ok, output = _run_fastlane_ruby(ruby_script, cwd=repo_root)
    if not ok:
        # 에러 메시지에서 핵심만 추출
        for line in output.splitlines():
            if "Error" in line or "error" in line:
                print(f"  경고: {line.strip()}")
                break
        else:
            print(f"  경고: Spaceship 실행 실패")
        return

    for line in output.strip().splitlines():
        line = line.strip()
        if line == "BUNDLE_ID_CREATED":
            print(f"  Bundle ID '{bundle_id}' 등록 완료")
        elif line == "BUNDLE_ID_EXISTS":
            print(f"  Bundle ID '{bundle_id}' 이미 등록됨")
        elif line == "APP_EXISTS":
            print(f"  App Store Connect에 앱이 이미 존재합니다")
        elif line == "APP_NOT_FOUND":
            print(f"  App Store Connect에 앱을 수동으로 생성하세요:")
            print(f"    1. https://appstoreconnect.apple.com/apps 접속")
            print(f"    2. '+' > 'New App' 클릭")
            print(f"    3. Bundle ID: {bundle_id} (드롭다운에서 선택)")
            print(f"    4. Name: {display_name}, SKU: {bundle_id}")
            print(f"    (API Key에 Admin 권한이 있으면 API로 자동 생성 가능)")


def _run_match(
    bundle_id: str,
    api_key_path: str,
    *,
    dry_run: bool = True,
) -> None:
    """match로 프로비저닝 프로필을 생성한다."""
    match_cmd = [
        "bundle", "exec", "fastlane", "match", "appstore",
        "-a", bundle_id,
        "--api_key_path", api_key_path,
    ]

    if dry_run:
        print(f"[dry-run] match appstore -a {bundle_id}")
        return

    print(f"  match 실행 중...")
    try:
        subprocess.run(match_cmd, check=True, capture_output=True, text=True)
        print(f"  프로비저닝 프로필 생성 완료")
    except subprocess.CalledProcessError as e:
        stderr = e.stderr or ""
        if "Invalid password" in stderr or "bad decrypt" in stderr:
            print(f"  경고: MATCH_PASSWORD가 필요합니다. CI에서 자동 처리됩니다.")
        else:
            for line in stderr.splitlines()[-3:]:
                if line.strip():
                    print(f"  경고: {line.strip()}")


def print_play_store_guide(
    app_name: str,
    app_id: str | None = None,
) -> None:
    """Play Store 수동 등록 가이드를 출력한다."""
    package_name = app_id or f"com.spiraldev.{app_name}"

    print("\n--- Google Play Store 등록 ---")
    print("Google Play Developer API는 신규 앱 생성을 미지원합니다.")
    print("수동으로 진행하세요:\n")
    print(f"  1. https://play.google.com/console/developers")
    print(f"  2. 패키지 이름: {package_name}")
    print(f"  3. 생성 후 첫 빌드 업로드:")
    print(f"     bundle exec fastlane android deploy_internal app:{app_name}")


def register_stores(
    app_name: str,
    display_name: str = "",
    *,
    app_id: str | None = None,
    ios_bundle_id: str | None = None,
    repo_root: Path | None = None,
    dry_run: bool = True,
) -> None:
    """App Store 등록 + Play Store 가이드를 실행한다."""
    register_app_store(
        app_name,
        display_name or app_name,
        ios_bundle_id,
        repo_root=repo_root,
        dry_run=dry_run,
    )
    print_play_store_guide(app_name, app_id)
