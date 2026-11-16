"""Threads 게시 설정."""
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Mapping

from common.envfile import load_env

PKG_DIR = Path(__file__).resolve().parent
LEDGER_FILE = PKG_DIR / "state" / "published.jsonl"

DEFAULTS: Mapping[str, str] = {
    "MKT_THREADS_API_HOST": "https://graph.threads.net",
    "MKT_THREADS_API_VERSION": "v1.0",
    "MKT_THREADS_MEDIA_HOST": "uguu",
}
REQUIRED = ("MKT_THREADS_USER_ID", "MKT_THREADS_TOKEN")


@dataclass(frozen=True)
class Config:
    user_id: str
    token: str
    api_host: str
    api_version: str
    host_provider: str  # 미디어 공개 URL 제공자: uguu | none
    app_id: str = ""        # OAuth 전용 (auth-url, exchange-code)
    app_secret: str = ""    # OAuth 전용. 이용 사례 > Threads API 액세스 > 설정 > Threads 앱 시크릿 코드
    redirect_uri: str = ""  # OAuth 전용. 같은 화면 "리디렉션 콜백 URL"에 등록한 값과 정확히 일치해야 함

    @property
    def api_base(self) -> str:
        return f"{self.api_host.rstrip('/')}/{self.api_version}"


def config_from(values: Mapping[str, str]) -> Config:
    return Config(
        user_id=values["MKT_THREADS_USER_ID"],
        token=values["MKT_THREADS_TOKEN"],
        api_host=values["MKT_THREADS_API_HOST"],
        api_version=values["MKT_THREADS_API_VERSION"],
        host_provider=values["MKT_THREADS_MEDIA_HOST"],
        app_id=values.get("MKT_THREADS_APP_ID", ""),
        app_secret=values.get("MKT_THREADS_APP_SECRET", ""),
        redirect_uri=values.get("MKT_THREADS_REDIRECT_URI", ""),
    )


def load_config() -> Config:
    return config_from(load_env(DEFAULTS, REQUIRED))
