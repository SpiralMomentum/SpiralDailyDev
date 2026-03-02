"""빌드 전 준비: gitignored 파일을 생성한다.

release.yaml의 ci.gitIgnoredFiles 설정을 읽어
CI와 로컬 모두에서 동일하게 빌드 전 파일을 생성한다.
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Any, Dict


def prepare(
    app_name: str,
    app_config: Dict[str, Any],
    *,
    repo_root: Path,
) -> None:
    """release.yaml ci.gitIgnoredFiles 기반으로 빌드 전 파일을 생성한다."""
    ci = app_config.get("ci") or {}
    git_ignored_files = ci.get("gitIgnoredFiles") or []

    if not git_ignored_files:
        print(f"[prepare] {app_name}: gitignored 파일 없음")
        return

    project_path = repo_root / app_config.get("projectPath", f"apps/{app_name}")

    for entry in git_ignored_files:
        rel_path = entry.get("path")
        if not rel_path:
            continue

        target = project_path / rel_path

        if target.exists():
            print(f"[prepare] {app_name}: {rel_path} (이미 존재, 스킵)")
            continue

        target.parent.mkdir(parents=True, exist_ok=True)

        # secret 참조: 환경변수에서 값을 가져온다
        secret_name = entry.get("secret")
        content = entry.get("content")

        if secret_name:
            secret_value = os.environ.get(secret_name, "")
            if secret_value:
                target.write_text(secret_value, encoding="utf-8")
                print(f"[prepare] {app_name}: {rel_path} (secret {secret_name})")
            else:
                # 환경변수가 없으면 더미 파일 생성 (로컬 빌드/테스트용)
                _write_dummy(target, rel_path)
                print(f"[prepare] {app_name}: {rel_path} (더미, {secret_name} 미설정)")
        elif content:
            target.write_text(content, encoding="utf-8")
            print(f"[prepare] {app_name}: {rel_path} (content)")
        else:
            _write_dummy(target, rel_path)
            print(f"[prepare] {app_name}: {rel_path} (더미)")


def _write_dummy(path: Path, rel_path: str) -> None:
    """파일 확장자에 따라 적절한 더미 내용을 생성한다."""
    if rel_path.endswith(".json"):
        path.write_text("{}", encoding="utf-8")
    elif rel_path.endswith(".dart"):
        path.write_text("// auto-generated dummy\n", encoding="utf-8")
    else:
        path.write_text("", encoding="utf-8")
