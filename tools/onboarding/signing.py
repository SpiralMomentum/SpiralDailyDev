"""Android 서명: keystore 생성과 중앙 GitHub Secret(ANDROID_KEYSTORES_BASE64, ANDROID_SIGNING_CONFIG) 갱신.

로컬 signing/ 디렉토리가 원본이고, GitHub Secret은 그 묶음 사본이다.
"""

from __future__ import annotations

import base64
import gzip
import io
import json
import secrets
import tarfile
from pathlib import Path
from typing import Callable, Dict, List, Mapping, Optional, Sequence, Tuple

from common.config import Config, org, path_for
from common.effects import Effects, done

KEYSTORE = "release.keystore"
PROPERTIES = "key.properties"


def key_properties(store_password: str, key_password: str, alias: str, store_file: Path) -> str:
    return (
        f"storePassword={store_password}\n"
        f"keyPassword={key_password}\n"
        f"keyAlias={alias}\n"
        f"storeFile={store_file}\n"
    )


def parse_properties(text: str) -> Dict[str, str]:
    pairs = (line.partition("=") for line in text.splitlines() if "=" in line)
    return {k.strip(): v.strip() for k, _, v in pairs}


def signing_entry(props: Mapping[str, str], app: str) -> Dict[str, str]:
    return {
        "store_password": props.get("storePassword", ""),
        "key_password": props.get("keyPassword", ""),
        "key_alias": props.get("keyAlias", app),
    }


def keystore_bundle(keystores: Sequence[Tuple[str, bytes]]) -> bytes:
    """{app}/release.keystore 구조의 tar.gz. mtime을 0으로 고정해 입력이 같으면 출력도 같다."""
    buf = io.BytesIO()
    with gzip.GzipFile(fileobj=buf, mode="wb", mtime=0) as gz, tarfile.open(fileobj=gz, mode="w") as tar:
        for app, data in keystores:
            info = tarfile.TarInfo(f"{app}/{KEYSTORE}")
            info.size = len(data)
            tar.addfile(info, io.BytesIO(data))
    return buf.getvalue()


def central_secrets(entries: Sequence[Tuple[str, bytes, Mapping[str, str]]]) -> Dict[str, str]:
    """(app, keystore bytes, key.properties) 목록 -> GitHub Secret 이름별 값."""
    return {
        "ANDROID_SIGNING_CONFIG": json.dumps(
            {app: signing_entry(props, app) for app, _, props in entries}, indent=2, ensure_ascii=False
        ),
        "ANDROID_KEYSTORES_BASE64": base64.b64encode(keystore_bundle([(app, ks) for app, ks, _ in entries])).decode(),
    }


def keytool_command(keystore: Path, alias: str, store_password: str, key_password: str, dname: str) -> List[str]:
    return [
        "keytool", "-genkeypair", "-v",
        "-keystore", str(keystore),
        "-alias", alias,
        "-keyalg", "RSA", "-keysize", "2048", "-validity", "10000",
        "-storepass", store_password, "-keypass", key_password,
        "-dname", dname,
    ]


def signing_dir(cfg: Config, repo_root: Path, app: str) -> Path:
    return repo_root / path_for(cfg, "signing", app)


def setup_signing(
    effects: Effects,
    cfg: Config,
    repo_root: Path,
    app: str,
    new_password: Callable[[], str] = lambda: secrets.token_urlsafe(16),
) -> Optional[str]:
    """keystore가 없으면 생성하고 key.properties를 쓴 뒤 중앙 Secret을 갱신한다. 실패하면 이유를 돌려준다.

    keystore가 이미 있으면 비밀번호를 바꾸면 안 되므로 key.properties도 건드리지 않는다.
    """
    directory = signing_dir(cfg, repo_root, app)
    keystore = directory / KEYSTORE
    if effects.exists(keystore):
        effects.log(f"{keystore.relative_to(repo_root)} 이미 존재 — 생성 건너뜀")
    else:
        if not effects.which("keytool"):
            effects.log("경고: keytool을 찾을 수 없습니다.")
            return "keytool 없음"
        # keytool 기본 형식 PKCS12는 키 비밀번호를 따로 둘 수 없어 -keypass를 무시한다. 같은 값을 써야 한다.
        store_pw = key_pw = new_password()
        dname = f"CN={app}, {org(cfg, 'keystoreDname')}"
        effects.mkdir(directory)
        r = effects.run(
            keytool_command(keystore, app, store_pw, key_pw, dname),
            capture=True,
            label=f"keytool -genkeypair {keystore.relative_to(repo_root)}",
        )
        if not r.ok:
            effects.log(f"경고: keystore 생성 실패: {r.stderr.strip()}")
            return "keystore 생성 실패"
        effects.write_text(directory / PROPERTIES, key_properties(store_pw, key_pw, app, keystore))
        done(effects, f"{keystore.relative_to(repo_root)} 생성 완료")

    return upload_central_secrets(effects, cfg, repo_root)


def signing_apps(cfg: Config, repo_root: Path) -> List[str]:
    """중앙 번들 후보: release.yaml의 앱 + 로컬 signing 디렉토리에 있는 앱.

    release.yaml만 보면 그 브랜치에 없는 앱의 키가 번들에서 빠져, 업로드할 때 원격 번들에서 사라진다.
    """
    template = (cfg.get("paths") or {}).get("signing", "signing/{app}/android")
    root = repo_root / template.split("{app}")[0]
    local = [d.name for d in root.iterdir() if d.is_dir()] if root.is_dir() else []
    return sorted(set(cfg.get("apps") or {}) | set(local))


def collect_local(effects: Effects, cfg: Config, repo_root: Path) -> List[Tuple[str, bytes, Dict[str, str]]]:
    """로컬 keystore + key.properties가 모두 있는 앱."""
    found = []
    for app in signing_apps(cfg, repo_root):
        directory = signing_dir(cfg, repo_root, app)
        keystore, props = directory / KEYSTORE, directory / PROPERTIES
        if effects.exists(keystore) and effects.exists(props):
            found.append((app, effects.read_bytes(keystore), parse_properties(effects.read_text(props))))
    return found


def upload_central_secrets(effects: Effects, cfg: Config, repo_root: Path) -> Optional[str]:
    entries = collect_local(effects, cfg, repo_root)
    effects.log(f"중앙 Secret 번들 대상 {len(entries)}개 앱: {[a for a, _, _ in entries]}")
    if not entries:
        return None
    if not effects.which("gh"):
        effects.log("경고: gh CLI 없음 — 설치 후 python3 tools/onboarding/pack_keystores.py 실행")
        return "gh CLI 없음 — 중앙 Secret 미등록"

    repo = org(cfg, "githubRepo")
    for name, value in central_secrets(entries).items():
        r = effects.run(["gh", "secret", "set", name, "--repo", repo], input=value, capture=True,
                        label=f"gh secret set {name} --repo {repo}")
        if r.ok:
            done(effects, f"  {name} 등록 완료")
        else:
            effects.log(f"  {name} 등록 실패: {r.stderr.strip()}")
            return f"{name} 등록 실패"
    return None
