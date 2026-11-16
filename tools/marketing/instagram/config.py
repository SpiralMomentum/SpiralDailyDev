"""Instagram 게시 설정."""
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Mapping

from common.envfile import load_env

PKG_DIR = Path(__file__).resolve().parent
LEDGER_FILE = PKG_DIR / "state" / "published.jsonl"

# 2026-11-12 검증: Unified login(비즈니스 포트폴리오)에서 발급된 토큰은 EAA로 시작하는
# Facebook 토큰이라 graph.facebook.com에서만 동작한다. graph.instagram.com은 code 190.
DEFAULTS: Mapping[str, str] = {
    "MKT_IG_GRAPH_HOST": "https://graph.facebook.com",
    "MKT_IG_GRAPH_VERSION": "v24.0",
    "MKT_IG_MEDIA_HOST": "uguu",
}
REQUIRED = ("MKT_IG_USER_ID", "MKT_IG_TOKEN")


@dataclass(frozen=True)
class Config:
    ig_user_id: str
    token: str
    graph_host: str
    graph_version: str
    host_provider: str  # 미디어 공개 URL 제공자: uguu | none

    @property
    def graph_base(self) -> str:
        return f"{self.graph_host.rstrip('/')}/{self.graph_version}"


def config_from(values: Mapping[str, str]) -> Config:
    return Config(
        ig_user_id=values["MKT_IG_USER_ID"],
        token=values["MKT_IG_TOKEN"],
        graph_host=values["MKT_IG_GRAPH_HOST"],
        graph_version=values["MKT_IG_GRAPH_VERSION"],
        host_provider=values["MKT_IG_MEDIA_HOST"],
    )


def load_config() -> Config:
    return config_from(load_env(DEFAULTS, REQUIRED))
