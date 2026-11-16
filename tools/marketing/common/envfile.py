"""환경변수 로딩 (채널 공통).

값 우선순위: 기본값 < tools/marketing/.env < 프로세스 환경변수
CI(GitHub Actions)에서는 secrets를 환경변수로 주입하고, 로컬에서는 .env 파일을 쓴다.
"""
from __future__ import annotations

import os
from pathlib import Path
from typing import Iterable, Mapping

MARKETING_DIR = Path(__file__).resolve().parent.parent
ENV_FILE = MARKETING_DIR / ".env"


def parse_env(text: str) -> dict[str, str]:
    """KEY=VALUE 텍스트 -> dict (순수 함수)."""
    pairs = (line.strip().partition("=") for line in text.splitlines())
    return {k.strip(): v.strip().strip('"').strip("'")
            for k, sep, v in pairs if sep and k.strip() and not k.strip().startswith("#")}


def merge_sources(*sources: Mapping[str, str]) -> dict[str, str]:
    """뒤에 오는 소스가 우선. 빈 값은 무시 (순수 함수)."""
    return {k: v for src in sources for k, v in src.items() if v}


def missing_keys(values: Mapping[str, str], required: Iterable[str]) -> list:
    return [k for k in required if not values.get(k)]


def load_env(defaults: Mapping[str, str], required: Iterable[str], env_file: Path = ENV_FILE) -> dict[str, str]:
    file_vals = parse_env(env_file.read_text(encoding="utf-8")) if env_file.exists() else {}
    values = merge_sources(defaults, file_vals, os.environ)
    missing = missing_keys(values, required)
    if missing:
        raise SystemExit(f"설정 누락: {', '.join(missing)} ({env_file} 또는 환경변수)")
    return values
