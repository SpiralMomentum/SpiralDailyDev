#!/usr/bin/env python3
"""Conventional Commits 기반 changelog 생성기.

git log를 파싱하여 conventional commit 타입별로 그룹화된 changelog를 생성한다.
앱 scope 필터링과 태그 기반 범위 지정을 지원한다.

사용법:
    # 전체 changelog (최근 50개 커밋)
    python tools/changelog/changelog_generator.py

    # 특정 앱 scope만
    python tools/changelog/changelog_generator.py --scope daily_memo

    # 특정 태그 이후
    python tools/changelog/changelog_generator.py --since v1.0.0

    # 파일 출력
    python tools/changelog/changelog_generator.py --output CHANGELOG.md
"""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

# Conventional Commit 타입 -> changelog 섹션 매핑
TYPE_SECTIONS: Dict[str, str] = {
    "feat": "Features",
    "fix": "Bug Fixes",
    "refactor": "Refactoring",
    "perf": "Performance",
    "docs": "Documentation",
    "test": "Tests",
    "chore": "Chores",
    "ci": "CI/CD",
    "build": "Build",
    "style": "Style",
}

# changelog에 표시할 타입 순서 (위에서 아래)
TYPE_ORDER = ["feat", "fix", "perf", "refactor", "docs", "test", "ci", "build", "chore", "style"]

CONVENTIONAL_COMMIT_RE = re.compile(
    r"^(?P<type>\w+)"
    r"(?:\((?P<scope>[^)]+)\))?"
    r"(?P<breaking>!)?"
    r":\s*(?P<description>.+)$"
)


@dataclass
class ConventionalCommit:
    hash: str
    type: str
    scope: Optional[str]
    description: str
    breaking: bool
    date: str


def parse_git_log(since: Optional[str] = None, limit: int = 200) -> List[dict]:
    """git log를 파싱하여 커밋 목록을 반환한다."""
    cmd = ["git", "log", f"--max-count={limit}", "--format=%H|%as|%s"]
    if since:
        cmd.append(f"{since}..HEAD")

    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    commits = []
    for line in result.stdout.strip().splitlines():
        if not line:
            continue
        parts = line.split("|", 2)
        if len(parts) != 3:
            continue
        commits.append({
            "hash": parts[0],
            "date": parts[1],
            "subject": parts[2],
        })
    return commits


def parse_conventional_commit(commit: dict) -> Optional[ConventionalCommit]:
    """커밋 메시지를 conventional commit으로 파싱한다. 파싱 실패 시 None."""
    match = CONVENTIONAL_COMMIT_RE.match(commit["subject"])
    if not match:
        return None
    return ConventionalCommit(
        hash=commit["hash"][:7],
        type=match.group("type"),
        scope=match.group("scope"),
        description=match.group("description"),
        breaking=bool(match.group("breaking")),
        date=commit["date"],
    )


def filter_commits(
    commits: List[ConventionalCommit],
    scope: Optional[str] = None,
) -> List[ConventionalCommit]:
    """scope로 커밋을 필터링한다."""
    if not scope:
        return commits
    return [c for c in commits if c.scope == scope]


def group_by_type(commits: List[ConventionalCommit]) -> Dict[str, List[ConventionalCommit]]:
    """타입별로 커밋을 그룹화한다."""
    grouped: Dict[str, List[ConventionalCommit]] = defaultdict(list)
    for commit in commits:
        grouped[commit.type].append(commit)
    return grouped


def format_changelog(
    grouped: Dict[str, List[ConventionalCommit]],
    title: Optional[str] = None,
) -> str:
    """그룹화된 커밋을 markdown changelog로 포맷한다."""
    lines: List[str] = []

    if title:
        lines.append(f"# {title}")
    else:
        today = datetime.now().strftime("%Y-%m-%d")
        lines.append(f"# Changelog ({today})")
    lines.append("")

    # Breaking changes 먼저 출력
    breaking = []
    for commits in grouped.values():
        breaking.extend(c for c in commits if c.breaking)

    if breaking:
        lines.append("## BREAKING CHANGES")
        lines.append("")
        for commit in breaking:
            scope_str = f"**{commit.scope}**: " if commit.scope else ""
            lines.append(f"- {scope_str}{commit.description} ({commit.hash})")
        lines.append("")

    # 타입별 출력
    for commit_type in TYPE_ORDER:
        commits = grouped.get(commit_type, [])
        if not commits:
            continue

        section_name = TYPE_SECTIONS.get(commit_type, commit_type.capitalize())
        lines.append(f"## {section_name}")
        lines.append("")
        for commit in commits:
            scope_str = f"**{commit.scope}**: " if commit.scope else ""
            lines.append(f"- {scope_str}{commit.description} ({commit.hash})")
        lines.append("")

    # 분류되지 않은 타입
    unknown_types = set(grouped.keys()) - set(TYPE_ORDER)
    for commit_type in sorted(unknown_types):
        commits = grouped[commit_type]
        lines.append(f"## {commit_type.capitalize()}")
        lines.append("")
        for commit in commits:
            scope_str = f"**{commit.scope}**: " if commit.scope else ""
            lines.append(f"- {scope_str}{commit.description} ({commit.hash})")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def main(argv: List[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Conventional Commits 기반 changelog 생성기",
    )
    parser.add_argument("--since", help="이 태그/커밋 이후의 변경사항만 포함")
    parser.add_argument("--scope", help="특정 scope의 커밋만 포함 (예: daily_memo)")
    parser.add_argument("--limit", type=int, default=200, help="파싱할 최대 커밋 수 (기본: 200)")
    parser.add_argument("--title", help="changelog 제목 (기본: 날짜 기반)")
    parser.add_argument("--output", "-o", help="출력 파일 경로 (기본: stdout)")
    args = parser.parse_args(argv)

    raw_commits = parse_git_log(since=args.since, limit=args.limit)
    if not raw_commits:
        print("No commits found.", file=sys.stderr)
        return 0

    parsed = []
    skipped = 0
    for raw in raw_commits:
        commit = parse_conventional_commit(raw)
        if commit:
            parsed.append(commit)
        else:
            skipped += 1

    if skipped:
        print(f"Skipped {skipped} non-conventional commits.", file=sys.stderr)

    filtered = filter_commits(parsed, scope=args.scope)
    if not filtered:
        print("No matching commits found.", file=sys.stderr)
        return 0

    grouped = group_by_type(filtered)
    output = format_changelog(grouped, title=args.title)

    if args.output:
        Path(args.output).write_text(output, encoding="utf-8")
        print(f"Changelog written to {args.output}", file=sys.stderr)
    else:
        print(output)

    return 0


if __name__ == "__main__":
    sys.exit(main())
