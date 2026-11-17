"""Play Console 신규 등록: store/registration/register.py를 실행한다."""

from __future__ import annotations

import json
from pathlib import Path
from typing import List, Optional

from common.config import Config, path_for
from common.effects import Effects
from store.registration.register import REGISTER_PY, STEPS, load_contract, missing_fields


def manual_guide(package_name: str, app: str) -> List[str]:
    return [
        "수동으로 진행하세요:",
        "  1. https://play.google.com/console/developers",
        f"  2. 패키지 이름: {package_name}",
        "  3. 생성 후 첫 빌드 업로드:",
        f"     bundle exec fastlane android deploy_internal app:{app}",
    ]


def register_command(app: str, developer_id: str, backend: str) -> List[str]:
    return ["python3", str(REGISTER_PY), "--app", app, "--developer-id", developer_id, "--backend", backend]


def register_play_store(
    effects: Effects,
    cfg: Config,
    repo_root: Path,
    app: str,
    package_name: str,
    developer_id: Optional[str],
    backend: str,
) -> Optional[str]:
    """실패하면 이유를, 성공하면 None을 돌려준다."""
    listing = repo_root / path_for(cfg, "storeListing", app)
    if not developer_id or not effects.exists(listing):
        reason = "developer ID 없음" if not developer_id else f"{path_for(cfg, 'storeListing', app)} 없음"
        effects.log(f"\n--- Google Play Store 등록 건너뜀 ({reason}) ---")
        for line in manual_guide(package_name, app):
            effects.log(line)
        return reason

    effects.log("\n--- Google Play Store 등록 ---")
    missing = missing_fields(load_contract(), json.loads(effects.read_text(listing)), STEPS)
    if missing:
        for step, fields in missing.items():
            effects.log(f"  {step}: store_listing.json 누락 필드 {fields}")
        effects.log("경고: 누락 필드를 채운 뒤 다시 실행하세요")
        return f"store_listing.json 누락 필드 ({', '.join(missing)})"

    if not effects.run(register_command(app, developer_id, backend), cwd=repo_root).ok:
        effects.log("경고: Play Console 등록 실패")
        return "Play Console 등록 단계 실패 (위 [단계] 출력 참고)"
    return None
