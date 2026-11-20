"""Instagram Graph API 호출 함수. HTTP/재시도는 common.http_api 를 쓴다."""
from __future__ import annotations

from typing import Any

from common.http_api import ApiError as GraphError, call, compact, logger  # noqa: F401 (재노출)
from instagram.config import Config

log = logger("ig")


def get(cfg: Config, path: str, **params: Any) -> dict[str, Any]:
    return call(cfg.graph_base, cfg.token, "GET", path, **params)


def post(cfg: Config, path: str, **params: Any) -> dict[str, Any]:
    return call(cfg.graph_base, cfg.token, "POST", path, **params)


def delete(cfg: Config, path: str, **params: Any) -> dict[str, Any]:
    return call(cfg.graph_base, cfg.token, "DELETE", path, **params)
