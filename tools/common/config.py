"""release.yaml 중앙 설정 로딩과 순수 조회 함수."""

from __future__ import annotations

from pathlib import Path
from typing import Any, Dict, Mapping, Optional

import yaml

from common.names import snake_to_camel

REPO_ROOT = Path(__file__).resolve().parents[2]
CONFIG_PATH = REPO_ROOT / "release.yaml"

Config = Mapping[str, Any]


def load_config(path: Path = CONFIG_PATH) -> Dict[str, Any]:
    return yaml.safe_load(path.read_text(encoding="utf-8"))


def app_config(cfg: Config, app: str) -> Optional[Mapping[str, Any]]:
    return (cfg.get("apps") or {}).get(app)


def project_path(cfg: Config, app: str) -> str:
    return (app_config(cfg, app) or {}).get("projectPath", f"apps/{app}")


def org(cfg: Config, key: str) -> Any:
    return cfg["org"][key]


def default(cfg: Config, key: str) -> Any:
    return cfg["defaults"][key]


def path_for(cfg: Config, key: str, app: str) -> str:
    """paths 섹션 템플릿을 앱 이름으로 채운 저장소 기준 상대 경로."""
    return cfg["paths"][key].format(app=app)


def default_android_id(cfg: Config, app: str) -> str:
    return f"{org(cfg, 'packagePrefix')}.{app}"


def default_ios_bundle_id(cfg: Config, app: str) -> str:
    return f"{org(cfg, 'packagePrefix')}.{snake_to_camel(app)}"
