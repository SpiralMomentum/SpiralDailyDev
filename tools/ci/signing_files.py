#!/usr/bin/env python3
"""CI에서 Android 서명 파일(signing/<app>/android/release.keystore, key.properties)을 만든다.

우선순위: 앱별 개별 Secret(배포 실적이 있는 키) > 중앙 번들(ANDROID_KEYSTORES_BASE64 + ANDROID_SIGNING_CONFIG)
표준 라이브러리만 사용한다.

    APP=<app> [개별/중앙 Secret 환경변수] python3 tools/ci/signing_files.py
"""

from __future__ import annotations

import base64
import io
import json
import os
import sys
import tarfile
from pathlib import Path
from typing import Mapping, NamedTuple, Optional


class Signing(NamedTuple):
    source: str
    keystore: bytes
    store_password: str
    key_password: str
    alias: str


def from_legacy(env: Mapping[str, str]) -> Optional[Signing]:
    if not env.get("KEYSTORE_LEGACY"):
        return None
    return Signing("개별 Secret", base64.b64decode(env["KEYSTORE_LEGACY"]),
                   env["STORE_PASSWORD_LEGACY"], env["KEY_PASSWORD_LEGACY"], env["KEY_ALIAS_LEGACY"])


def from_central(env: Mapping[str, str], app: str) -> Optional[Signing]:
    config = json.loads(env.get("ANDROID_SIGNING_CONFIG") or "{}").get(app)
    if not config or not env.get("ANDROID_KEYSTORES_BASE64"):
        return None
    with tarfile.open(fileobj=io.BytesIO(base64.b64decode(env["ANDROID_KEYSTORES_BASE64"]))) as tar:
        try:
            keystore = tar.extractfile(tar.getmember(f"{app}/release.keystore")).read()
        except KeyError:
            return None
    return Signing("중앙 번들", keystore, config["store_password"], config["key_password"], config["key_alias"])


def resolve(env: Mapping[str, str], app: str) -> Optional[Signing]:
    return from_legacy(env) or from_central(env, app)


def key_properties(s: Signing, keystore_path: Path) -> str:
    return (f"storePassword={s.store_password}\nkeyPassword={s.key_password}\n"
            f"keyAlias={s.alias}\nstoreFile={keystore_path}\n")


def main() -> int:
    app = os.environ["APP"]
    signing = resolve(os.environ, app)
    if not signing:
        print(f"[signing] 오류: {app} keystore를 개별 Secret과 중앙 번들 어디에서도 찾을 수 없습니다", file=sys.stderr)
        return 1

    directory = Path(f"signing/{app}/android").resolve()
    directory.mkdir(parents=True, exist_ok=True)
    (directory / "release.keystore").write_bytes(signing.keystore)
    (directory / "key.properties").write_text(key_properties(signing, directory / "release.keystore"))
    print(f"[signing] {app}: {signing.source} 사용")
    return 0


if __name__ == "__main__":
    sys.exit(main())
