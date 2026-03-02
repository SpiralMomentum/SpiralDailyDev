"""snake_case <-> camelCase/PascalCase 변환 유틸리티."""

from __future__ import annotations

import re


def validate_app_name(name: str) -> None:
    """snake_case 형식의 앱 이름인지 검증한다.

    Raises:
        ValueError: 유효하지 않은 앱 이름
    """
    if not name:
        raise ValueError("앱 이름이 비어 있습니다")
    if not re.fullmatch(r"[a-z][a-z0-9]*(_[a-z0-9]+)*", name):
        raise ValueError(
            f"앱 이름 '{name}'은 snake_case 형식이어야 합니다 (예: my_new_app)"
        )


def snake_to_camel(name: str) -> str:
    """snake_case -> camelCase 변환.

    예: exchange_rate_calculator -> exchangeRateCalculator
    """
    parts = name.split("_")
    return parts[0] + "".join(p.capitalize() for p in parts[1:])


def snake_to_pascal(name: str) -> str:
    """snake_case -> PascalCase 변환.

    예: exchange_rate_calculator -> ExchangeRateCalculator
    """
    return "".join(p.capitalize() for p in name.split("_"))
