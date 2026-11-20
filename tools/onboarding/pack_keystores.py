#!/usr/bin/env python3
"""로컬 signing/ 의 keystore를 묶어 중앙 GitHub Secret 2개를 갱신한다.

    python3 tools/onboarding/pack_keystores.py [--dry-run]
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from common.config import REPO_ROOT, load_config
from common.effects import effects_for
from onboarding.signing import upload_central_secrets


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    problem = upload_central_secrets(effects_for(args.dry_run), load_config(), REPO_ROOT)
    if problem:
        print(f"실패: {problem}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
