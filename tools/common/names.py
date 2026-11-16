"""앱 이름 규칙 (순수 함수)."""

from __future__ import annotations

import re
from typing import Optional


def app_name_error(name: str) -> Optional[str]:
    """snake_case가 아니면 오류 메시지, 유효하면 None."""
    if not name:
        return "앱 이름이 비어 있습니다"
    if not re.fullmatch(r"[a-z][a-z0-9]*(_[a-z0-9]+)*", name):
        return f"앱 이름 '{name}'은 snake_case 형식이어야 합니다 (예: my_new_app)"
    return None


def snake_to_camel(name: str) -> str:
    parts = name.split("_")
    return parts[0] + "".join(p.capitalize() for p in parts[1:])
