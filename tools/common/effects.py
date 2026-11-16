"""부수효과 주입 계층.

순수 함수는 계산만 하고, 파일 쓰기/프로세스 실행/로그는 Effects를 통해서만 한다.
dry-run은 분기 대신 쓰기와 실행을 기록만 하는 Effects를 주입해서 처리한다.
"""

from __future__ import annotations

import os
import shlex
import shutil
import subprocess
import sys
from dataclasses import dataclass, replace
from pathlib import Path
from typing import Callable, Mapping, Optional, Sequence


@dataclass(frozen=True)
class RunResult:
    returncode: int
    stdout: str = ""
    stderr: str = ""

    @property
    def ok(self) -> bool:
        return self.returncode == 0


Run = Callable[..., RunResult]


@dataclass(frozen=True)
class Effects:
    read_text: Callable[[Path], str]
    read_bytes: Callable[[Path], bytes]
    exists: Callable[[Path], bool]
    write_text: Callable[[Path, str], None]
    mkdir: Callable[[Path], None]
    run: Run
    which: Callable[[str], Optional[str]]
    env: Mapping[str, str]
    log: Callable[[str], None]
    dry_run: bool = False


def _log(message: str) -> None:
    print(message, flush=True)


def _write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def _describe(cmd: Sequence[str], cwd: Optional[Path], label: Optional[str]) -> str:
    text = label or " ".join(shlex.quote(str(c)) for c in cmd)
    return f"{text}  (cwd: {cwd})" if cwd else text


def _real_run(
    cmd: Sequence[str],
    *,
    cwd: Optional[Path] = None,
    input: Optional[str] = None,
    env: Optional[Mapping[str, str]] = None,
    capture: bool = False,
    label: Optional[str] = None,
) -> RunResult:
    """label은 로그에 명령 대신 표시할 문자열 (비밀값이 인자에 있을 때 사용)."""
    if not capture:
        _log(f"  -> {_describe(cmd, cwd, label)}")
    r = subprocess.run(
        [str(c) for c in cmd],
        cwd=cwd,
        input=input,
        env={**os.environ, **env} if env else None,
        capture_output=capture,
        text=True,
    )
    return RunResult(r.returncode, r.stdout or "", r.stderr or "")


def real_effects() -> Effects:
    return Effects(
        read_text=lambda p: p.read_text(encoding="utf-8"),
        read_bytes=lambda p: p.read_bytes(),
        exists=lambda p: p.exists(),
        write_text=_write_text,
        mkdir=lambda p: p.mkdir(parents=True, exist_ok=True),
        run=_real_run,
        which=shutil.which,
        env=dict(os.environ),
        log=_log,
    )


def dry_run_effects(base: Effects) -> Effects:
    """읽기는 그대로, 쓰기와 실행은 기록만 한다."""

    def write_text(path: Path, content: str) -> None:
        base.log(f"  [dry-run] 쓰기: {path}")

    def run(cmd: Sequence[str], *, cwd: Optional[Path] = None, label: Optional[str] = None, **_: object) -> RunResult:
        base.log(f"  [dry-run] {_describe(cmd, cwd, label)}")
        return RunResult(0)

    return replace(base, write_text=write_text, mkdir=lambda p: None, run=run, dry_run=True)


def effects_for(dry_run: bool) -> Effects:
    real = real_effects()
    return dry_run_effects(real) if dry_run else real


def done(effects: Effects, message: str) -> None:
    """작업 결과 로그. dry-run이면 실제로 일어나지 않았음을 표시한다."""
    effects.log(f"  [dry-run 예정] {message}" if effects.dry_run else message)


def fail(message: str) -> int:
    print(f"오류: {message}", file=sys.stderr)
    return 1
