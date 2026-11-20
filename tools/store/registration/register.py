#!/usr/bin/env python3
"""
Play Console 등록 dispatcher.

각 백엔드 CLI를 subprocess로 호출하고 JSON 결과를 수집한다.
백엔드 CLI 계약: contract.json 참조.

Usage:
  python3 tools/store/registration/register.py --app color_snap --developer-id 764310...
  python3 tools/store/registration/register.py --app color_snap --developer-id 764310... --backend playwright
  python3 tools/store/registration/register.py --app color_snap --developer-id 764310... --step set_privacy_policy --app-id 497253...
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, List, Mapping, Optional, Sequence

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from common.config import REPO_ROOT, default, load_config, org, path_for

HERE = Path(__file__).resolve().parent
REGISTER_PY = HERE / "register.py"
BACKENDS_DIR = HERE / "backends"

STEPS = [
    "create_app",
    "set_store_settings",
    "set_privacy_policy",
    "set_ads",
    "set_app_access",
    "set_content_rating",
    "set_target_audience",
]

BACKEND_COMMANDS = {
    "playwright":       ["node", str(BACKENDS_DIR / "playwright" / "index.js")],
    "claude_chrome":    ["bash", str(BACKENDS_DIR / "claude_chrome" / "run.sh")],
    "chrome_extension": ["python3", str(BACKENDS_DIR / "chrome_extension" / "server.py")],
}


def load_contract() -> Dict[str, Any]:
    return json.loads((HERE / "contract.json").read_text())


def missing_fields(contract: Mapping[str, Any], listing: Mapping[str, Any], steps: Sequence[str]) -> Dict[str, List[str]]:
    """단계별로 store_listing.json에 없는 필수 필드. 모두 있으면 빈 dict."""
    result = {
        step: [f for f in contract["steps"][step].get("required_config_fields", []) if f not in listing]
        for step in steps
    }
    return {step: fields for step, fields in result.items() if fields}


def steps_to_run(step: Optional[str], app_id: Optional[str]) -> List[str]:
    steps = [step] if step else STEPS
    return [s for s in steps if not (app_id and s == "create_app")]


def backend_command(backend: str, step: str, listing: Mapping[str, Any], app_id: Optional[str], developer_id: str) -> List[str]:
    cmd = BACKEND_COMMANDS[backend] + ["--step", step, "--config", json.dumps(listing), "--developer-id", developer_id]
    return cmd + (["--app-id", app_id] if app_id else [])


def parse_result(stdout: str, returncode: int) -> Dict[str, Any]:
    try:
        return json.loads(stdout.strip())
    except json.JSONDecodeError:
        return {"success": False, "app_id": None, "message": f"exit {returncode}: {stdout[:200]}"}


def call_backend(cmd: List[str]) -> Dict[str, Any]:
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.stderr:
        print(result.stderr, file=sys.stderr, end="")
    return parse_result(result.stdout, result.returncode)


def main() -> None:
    cfg = load_config()
    parser = argparse.ArgumentParser()
    parser.add_argument("--app", required=True)
    parser.add_argument("--developer-id", default=str(org(cfg, "playDeveloperId")))
    parser.add_argument("--backend", choices=list(BACKEND_COMMANDS), default=default(cfg, "registrationBackend"))
    parser.add_argument("--app-id", help="이미 생성된 앱 ID (create_app 건너뜀)")
    parser.add_argument("--step", choices=STEPS, help="특정 단계만 실행")
    parser.add_argument("--dry-run", action="store_true", help="실제 실행 없이 config/계약 검증만")
    args = parser.parse_args()

    listing_path = REPO_ROOT / path_for(cfg, "storeListing", args.app)
    if not listing_path.exists():
        print(f"오류: {listing_path} 없음", file=sys.stderr)
        sys.exit(1)
    listing = json.loads(listing_path.read_text())
    steps = steps_to_run(args.step, args.app_id)

    if args.dry_run:
        missing = missing_fields(load_contract(), listing, steps)
        print(f"[dry-run] app: {args.app}  backend: {args.backend}")
        print(f"[dry-run] config keys: {list(listing.keys())}\n")
        for step in steps:
            status = f"누락 필드: {missing[step]}" if step in missing else "OK"
            print(f"  {step:<30} {status}")
        print(f"\n백엔드 커맨드: {' '.join(BACKEND_COMMANDS[args.backend])}")
        return

    app_id = args.app_id
    for step in steps:
        print(f"\n[{step}] 시작...")
        result = call_backend(backend_command(args.backend, step, listing, app_id, args.developer_id))
        app_id = result.get("app_id") or app_id
        print(f"[{step}] " + ("완료" if result["success"] else f"실패: {result.get('message', '')}"))
        if not result["success"]:
            sys.exit(1)
        if not app_id:
            print(f"[{step}] 앱 ID를 얻지 못해 다음 단계를 진행할 수 없습니다: {result.get('message', '')}")
            sys.exit(1)

    print(f"\n등록 완료. APP_ID: {app_id}")


if __name__ == "__main__":
    main()
