"""Android signing 인프라를 설정한다."""

from __future__ import annotations

import secrets
import shutil
import subprocess
from pathlib import Path


def setup_signing(
    repo_root: Path,
    app_name: str,
    *,
    dry_run: bool = True,
) -> dict[str, str] | None:
    """Android signing 인프라를 설정한다.

    1. signing/{app}/android/ 디렉토리 생성
    2. keytool로 release keystore 생성
    3. key.properties 파일 생성
    4. CI용 GitHub Secrets 값 출력

    Returns:
        GitHub Secrets 등록에 필요한 정보 dict (dry_run이면 None)
    """
    signing_dir = repo_root / "signing" / app_name / "android"
    keystore_path = signing_dir / "release.keystore"
    properties_path = signing_dir / "key.properties"

    app_upper = app_name.upper()
    store_password = secrets.token_urlsafe(16)
    key_password = secrets.token_urlsafe(16)
    key_alias = app_name

    if dry_run:
        print(f"[dry-run] signing/{app_name}/android/ 디렉토리 생성 예정")
        print(f"[dry-run] release.keystore 생성 예정 (RSA 2048, 10000일)")
        print(f"[dry-run] key.properties 생성 예정")
        print(f"[dry-run] GitHub Secrets 등록 필요:")
        print(f"  ANDROID_KEYSTORE_{app_upper}_BASE64")
        print(f"  ANDROID_STORE_PASSWORD_{app_upper}")
        print(f"  ANDROID_KEY_PASSWORD_{app_upper}")
        print(f"  ANDROID_KEY_ALIAS_{app_upper}")
        return None

    # keytool 존재 확인
    if not shutil.which("keytool"):
        print("경고: keytool을 찾을 수 없습니다. JDK가 설치되어 있는지 확인하세요.")
        return None

    signing_dir.mkdir(parents=True, exist_ok=True)

    if keystore_path.exists():
        print(f"signing/{app_name}/android/release.keystore가 이미 존재합니다. 스킵합니다.")
    else:
        keytool_cmd = [
            "keytool",
            "-genkeypair",
            "-v",
            "-keystore", str(keystore_path),
            "-alias", key_alias,
            "-keyalg", "RSA",
            "-keysize", "2048",
            "-validity", "10000",
            "-storepass", store_password,
            "-keypass", key_password,
            "-dname", f"CN={app_name}, OU=SpiralDev, O=SpiralDev, L=Seoul, ST=Seoul, C=KR",
        ]
        try:
            subprocess.run(keytool_cmd, check=True, capture_output=True, text=True)
            print(f"signing/{app_name}/android/release.keystore를 생성했습니다")
        except subprocess.CalledProcessError as e:
            print(f"경고: keystore 생성 실패: {e.stderr}")
            return None

    # key.properties 생성
    properties_content = (
        f"storePassword={store_password}\n"
        f"keyPassword={key_password}\n"
        f"keyAlias={key_alias}\n"
        f"storeFile=release.keystore\n"
    )
    properties_path.write_text(properties_content, encoding="utf-8")
    print(f"signing/{app_name}/android/key.properties를 생성했습니다")

    # base64 인코딩
    import base64
    keystore_b64 = base64.b64encode(keystore_path.read_bytes()).decode()

    secrets_info = {
        f"ANDROID_KEYSTORE_{app_upper}_BASE64": keystore_b64,
        f"ANDROID_STORE_PASSWORD_{app_upper}": store_password,
        f"ANDROID_KEY_PASSWORD_{app_upper}": key_password,
        f"ANDROID_KEY_ALIAS_{app_upper}": key_alias,
    }

    # gh CLI로 GitHub Secrets 자동 등록
    if shutil.which("gh"):
        repo = _detect_github_repo()
        if repo:
            print(f"\nGitHub Secrets를 '{repo}'에 등록 중...")
            all_ok = True
            for name, value in secrets_info.items():
                try:
                    subprocess.run(
                        ["gh", "secret", "set", name, "--repo", repo],
                        input=value,
                        check=True,
                        capture_output=True,
                        text=True,
                    )
                except subprocess.CalledProcessError as e:
                    print(f"  경고: {name} 등록 실패: {e.stderr.strip()}")
                    all_ok = False
            if all_ok:
                print("GitHub Secrets 등록 완료")
            else:
                print("일부 Secrets 등록에 실패했습니다. 수동으로 등록하세요.")
        else:
            print("\n경고: GitHub 리포지토리를 감지할 수 없습니다")
            _print_secrets_manual(secrets_info)
    else:
        print("\n경고: gh CLI를 찾을 수 없습니다. GitHub Secrets를 수동으로 등록하세요.")
        _print_secrets_manual(secrets_info)

    return secrets_info


def _detect_github_repo() -> str | None:
    """gh CLI로 현재 리포지토리의 owner/repo를 감지한다."""
    try:
        result = subprocess.run(
            ["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"],
            capture_output=True, text=True, check=True,
        )
        return result.stdout.strip() or None
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


def _print_secrets_manual(secrets_info: dict[str, str]) -> None:
    """수동 등록 안내를 출력한다."""
    print("\n등록해야 할 GitHub Secrets:")
    for name, value in secrets_info.items():
        display_value = value if len(value) < 40 else value[:20] + "...(truncated)"
        print(f"  {name} = {display_value}")
