"""Android signing 인프라를 설정하고 중앙화된 GitHub Secrets를 갱신한다."""

from __future__ import annotations

import base64
import io
import json
import secrets
import shutil
import subprocess
import tarfile
from pathlib import Path


def setup_signing(
    repo_root: Path,
    app_name: str,
    *,
    dry_run: bool = True,
) -> None:
    """Android signing 인프라를 설정한다.

    1. signing/{app}/android/ 디렉토리 생성
    2. keytool로 release keystore 생성
    3. key.properties 파일 생성
    4. ANDROID_KEYSTORES_BASE64 + ANDROID_SIGNING_CONFIG 갱신
    """
    signing_dir = repo_root / "signing" / app_name / "android"
    keystore_path = signing_dir / "release.keystore"
    properties_path = signing_dir / "key.properties"

    store_password = secrets.token_urlsafe(16)
    key_password = secrets.token_urlsafe(16)
    key_alias = app_name

    if dry_run:
        print(f"[dry-run] signing/{app_name}/android/ 생성 예정")
        print(f"[dry-run] release.keystore 생성 예정 (RSA 2048, 10000일)")
        print(f"[dry-run] ANDROID_KEYSTORES_BASE64 / ANDROID_SIGNING_CONFIG 갱신 예정")
        return

    if not shutil.which("keytool"):
        print("경고: keytool을 찾을 수 없습니다.")
        return

    signing_dir.mkdir(parents=True, exist_ok=True)

    if keystore_path.exists():
        print(f"signing/{app_name}/android/release.keystore 이미 존재 — 스킵")
    else:
        cmd = [
            "keytool", "-genkeypair", "-v",
            "-keystore", str(keystore_path),
            "-alias", key_alias,
            "-keyalg", "RSA", "-keysize", "2048", "-validity", "10000",
            "-storepass", store_password, "-keypass", key_password,
            "-dname", f"CN={app_name}, OU=SpiralDev, O=SpiralDev, L=Seoul, ST=Seoul, C=KR",
        ]
        try:
            subprocess.run(cmd, check=True, capture_output=True, text=True)
            print(f"signing/{app_name}/android/release.keystore 생성 완료")
        except subprocess.CalledProcessError as e:
            print(f"경고: keystore 생성 실패: {e.stderr}")
            return

    properties_path.write_text(
        f"storePassword={store_password}\n"
        f"keyPassword={key_password}\n"
        f"keyAlias={key_alias}\n"
        f"storeFile=release.keystore\n",
        encoding="utf-8",
    )
    print(f"signing/{app_name}/android/key.properties 생성 완료")

    _upload_central_secrets(repo_root)


def _upload_central_secrets(repo_root: Path) -> None:
    """signing/ 아래 모든 앱의 keystore + key.properties를 묶어 GitHub Secrets 2개를 갱신한다."""
    signing_root = repo_root / "signing"
    signing_config: dict[str, dict] = {}
    buf = io.BytesIO()

    with tarfile.open(fileobj=buf, mode="w:gz") as tar:
        for app_dir in sorted(signing_root.iterdir()):
            if not app_dir.is_dir():
                continue
            keystore = app_dir / "android" / "release.keystore"
            props_file = app_dir / "android" / "key.properties"
            if not keystore.exists() or not props_file.exists():
                continue

            app_name = app_dir.name

            # tar에 keystore 추가
            tar.add(str(keystore), arcname=f"{app_name}/release.keystore")

            # key.properties 파싱
            props: dict[str, str] = {}
            for line in props_file.read_text(encoding="utf-8").splitlines():
                if "=" in line:
                    k, _, v = line.partition("=")
                    props[k.strip()] = v.strip()

            signing_config[app_name] = {
                "store_password": props.get("storePassword", ""),
                "key_password": props.get("keyPassword", ""),
                "key_alias": props.get("keyAlias", app_name),
            }

    keystores_b64 = base64.b64encode(buf.getvalue()).decode()
    config_json = json.dumps(signing_config, indent=2, ensure_ascii=False)

    print(f"\n{len(signing_config)}개 앱 포함된 번들 생성 완료: {list(signing_config)}")

    if not shutil.which("gh"):
        print("경고: gh CLI 없음 — 아래 값을 GitHub Secrets에 직접 등록하세요")
        print(f"  ANDROID_SIGNING_CONFIG = {config_json[:60]}...")
        print(f"  ANDROID_KEYSTORES_BASE64 = {keystores_b64[:40]}...")
        return

    repo = _detect_github_repo()
    if not repo:
        print("경고: GitHub 리포지토리 감지 실패")
        return

    for name, value in [
        ("ANDROID_SIGNING_CONFIG", config_json),
        ("ANDROID_KEYSTORES_BASE64", keystores_b64),
    ]:
        try:
            subprocess.run(
                ["gh", "secret", "set", name, "--repo", repo],
                input=value, check=True, capture_output=True, text=True,
            )
            print(f"  {name} 등록 완료")
        except subprocess.CalledProcessError as e:
            print(f"  {name} 등록 실패: {e.stderr.strip()}")


def _detect_github_repo() -> str | None:
    try:
        r = subprocess.run(
            ["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"],
            capture_output=True, text=True, check=True,
        )
        return r.stdout.strip() or None
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None
