"""빌드 전 준비: release.yaml ci.gitIgnoredFiles 기반으로 gitignored 파일을 만든다."""

from __future__ import annotations

from pathlib import Path
from typing import Any, List, Mapping, NamedTuple, Sequence

from common.config import Config, REPO_ROOT, app_config, project_path
from common.effects import Effects


class FileSpec(NamedTuple):
    rel_path: str
    content: str
    source: str


def dummy_content(rel_path: str) -> str:
    if rel_path.endswith(".json"):
        return "{}"
    if rel_path.endswith(".dart"):
        return "// auto-generated dummy\n"
    return ""


def _spec(entry: Mapping[str, Any], env: Mapping[str, str]) -> FileSpec:
    rel = entry["path"]
    secret = entry.get("secret")
    if secret:
        value = env.get(secret, "")
        return FileSpec(rel, value, f"secret {secret}") if value else FileSpec(rel, dummy_content(rel), f"더미, {secret} 미설정")
    if entry.get("content"):
        return FileSpec(rel, entry["content"], "content")
    return FileSpec(rel, dummy_content(rel), "더미")


def plan_ignored_files(entries: Sequence[Mapping[str, Any]], env: Mapping[str, str]) -> List[FileSpec]:
    return [_spec(e, env) for e in entries if e.get("path")]


def prepare(effects: Effects, cfg: Config, app: str, repo_root: Path = REPO_ROOT) -> None:
    entries = ((app_config(cfg, app) or {}).get("ci") or {}).get("gitIgnoredFiles") or []
    if not entries:
        effects.log(f"[prepare] {app}: gitignored 파일 없음")
        return

    base = repo_root / project_path(cfg, app)
    for spec in plan_ignored_files(entries, effects.env):
        target = base / spec.rel_path
        if effects.exists(target):
            effects.log(f"[prepare] {app}: {spec.rel_path} (이미 존재, 스킵)")
            continue
        effects.write_text(target, spec.content)
        effects.log(f"[prepare] {app}: {spec.rel_path} ({spec.source})")
