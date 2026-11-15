#!/usr/bin/env python3
"""signing/ 아래 모든 keystore를 묶어 GitHub Secrets 2개를 갱신한다.

신규 앱 추가 후 또는 패스워드 변경 후 실행:
    python3 tools/pipeline/pack_keystores.py
    python3 tools/pipeline/pack_keystores.py --dry-run
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "steps"))
from setup_signing import _upload_central_secrets

import argparse


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parent.parent.parent

    if args.dry_run:
        signing_root = repo_root / "signing"
        apps = [d.name for d in sorted(signing_root.iterdir())
                if d.is_dir() and (d / "android" / "release.keystore").exists()]
        print(f"[dry-run] 번들에 포함될 앱: {apps}")
        print("[dry-run] ANDROID_SIGNING_CONFIG + ANDROID_KEYSTORES_BASE64 갱신 예정")
        return

    _upload_central_secrets(repo_root)


if __name__ == "__main__":
    main()
