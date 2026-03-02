"""GitHub Actions 워크플로우 파일에 앱을 추가한다.

GitHub Actions YAML은 ${{ }} 표현식을 포함하므로 YAML 파서 사용 불가.
정규식 기반 텍스트 삽입을 사용한다.
"""

from __future__ import annotations

import re
from pathlib import Path


def _read_preserving_newlines(path: Path) -> tuple[str, str]:
    """파일을 읽으면서 원본 줄바꿈 문자를 감지하고, LF로 정규화한다."""
    raw = path.read_bytes()
    if b"\r\n" in raw:
        newline = "\r\n"
    else:
        newline = "\n"
    text = raw.decode("utf-8").replace("\r\n", "\n")
    return text, newline


def _write_preserving_newlines(path: Path, text: str, newline: str) -> None:
    """원본 줄바꿈 문자를 유지하면서 파일을 쓴다."""
    if newline == "\r\n":
        # 먼저 모든 줄바꿈을 LF로 통일 후 CRLF로 변환
        normalized = text.replace("\r\n", "\n")
        output = normalized.replace("\n", "\r\n")
    else:
        output = text
    path.write_bytes(output.encode("utf-8"))


def _insert_after_last_match(
    text: str,
    pattern: str,
    new_line: str,
) -> str:
    """정규식 패턴의 마지막 매치 뒤에 새 줄을 삽입한다."""
    matches = list(re.finditer(pattern, text))
    if not matches:
        raise ValueError(f"패턴을 찾을 수 없습니다: {pattern}")
    last = matches[-1]
    insert_pos = last.end()
    return text[:insert_pos] + "\n" + new_line + text[insert_pos:]


def _app_already_in_block(text: str, block_pattern: str, app_name: str) -> bool:
    """특정 블록 내에 앱 이름이 이미 존재하는지 확인한다."""
    match = re.search(block_pattern, text, re.DOTALL)
    if match and app_name in match.group(0):
        return True
    return False


def add_to_release_all(
    path: Path,
    app_name: str,
    *,
    exclude_from_release: bool = False,
    dry_run: bool = True,
) -> None:
    """release-all.yaml의 3개 matrix에 앱을 추가한다."""
    text, newline = _read_preserving_newlines(path)
    modified = text

    # 1) test matrix: 모든 앱 포함
    # test job의 matrix.app 블록에서 마지막 항목 뒤에 삽입
    test_block = r"(  test:.*?matrix:\s*\n\s+app:\s*\n)((?:\s+- \w+\n)+)"
    test_match = re.search(test_block, modified, re.DOTALL)
    if test_match:
        block_text = test_match.group(2)
        if app_name not in block_text:
            # 마지막 항목의 들여쓰기를 따라감
            last_item = re.findall(r"^( +- \w+)$", block_text, re.MULTILINE)
            if last_item:
                indent = re.match(r"^( +)", last_item[-1]).group(1)
                new_item = f"{indent}- {app_name}\n"
                end_pos = test_match.end(2)
                modified = modified[:end_pos] + new_item + modified[end_pos:]
                if dry_run:
                    print(f"[dry-run] release-all.yaml test matrix에 '{app_name}' 추가 예정")
        else:
            print(f"release-all.yaml test matrix에 '{app_name}'이 이미 존재합니다")
    else:
        print("경고: release-all.yaml에서 test matrix 블록을 찾을 수 없습니다")

    # 2) deploy-android matrix
    if not exclude_from_release:
        android_block = r"(  deploy-android:.*?matrix:\s*\n\s+app:\s*\n)((?:\s+- \w+\n)+)"
        android_match = re.search(android_block, modified, re.DOTALL)
        if android_match:
            block_text = android_match.group(2)
            if app_name not in block_text:
                last_item = re.findall(r"^( +- \w+)$", block_text, re.MULTILINE)
                if last_item:
                    indent = re.match(r"^( +)", last_item[-1]).group(1)
                    new_item = f"{indent}- {app_name}\n"
                    end_pos = android_match.end(2)
                    modified = modified[:end_pos] + new_item + modified[end_pos:]
                    if dry_run:
                        print(f"[dry-run] release-all.yaml deploy-android matrix에 '{app_name}' 추가 예정")
            else:
                print(f"release-all.yaml deploy-android matrix에 '{app_name}'이 이미 존재합니다")

    # 3) deploy-ios matrix
    if not exclude_from_release:
        ios_block = r"(  deploy-ios:.*?matrix:\s*\n\s+app:\s*\n)((?:\s+- \w+\n)+)"
        ios_match = re.search(ios_block, modified, re.DOTALL)
        if ios_match:
            block_text = ios_match.group(2)
            if app_name not in block_text:
                last_item = re.findall(r"^( +- \w+)$", block_text, re.MULTILINE)
                if last_item:
                    indent = re.match(r"^( +)", last_item[-1]).group(1)
                    new_item = f"{indent}- {app_name}\n"
                    end_pos = ios_match.end(2)
                    modified = modified[:end_pos] + new_item + modified[end_pos:]
                    if dry_run:
                        print(f"[dry-run] release-all.yaml deploy-ios matrix에 '{app_name}' 추가 예정")
            else:
                print(f"release-all.yaml deploy-ios matrix에 '{app_name}'이 이미 존재합니다")

    if not dry_run and modified != text:
        _write_preserving_newlines(path, modified, newline)
        print(f"release-all.yaml에 '{app_name}'을 추가했습니다")


def add_to_ci(
    path: Path,
    app_name: str,
    *,
    coverage_threshold: int = 50,
    dry_run: bool = True,
) -> None:
    """ci.yaml의 detect-changes 필터에 앱을 추가한다."""
    text, newline = _read_preserving_newlines(path)

    # detect-changes filters 블록에서 마지막 필터 뒤에 새 필터 추가
    # 패턴: "            app_name:\n              - 'apps/app_name/**'\n              - 'packages/**'"
    filter_pattern = r"(            \w+:\n              - 'apps/\w+/\*\*'\n              - 'packages/\*\*')"
    matches = list(re.finditer(filter_pattern, text))

    if not matches:
        print("경고: ci.yaml에서 필터 블록을 찾을 수 없습니다")
        return

    # 이미 존재하는지 확인
    if re.search(rf"            {app_name}:", text):
        print(f"ci.yaml 필터에 '{app_name}'이 이미 존재합니다")
        return

    last_match = matches[-1]
    new_filter = (
        f"\n            {app_name}:\n"
        f"              - 'apps/{app_name}/**'\n"
        f"              - 'packages/**'"
    )

    modified = text[:last_match.end()] + new_filter + text[last_match.end():]

    # 커버리지 임계값 추가 (기본값 50이 아닌 경우)
    if coverage_threshold != 50:
        # case 블록에서 *) 기본값 앞에 새 앱 임계값 추가
        case_pattern = r"(\s+\*\)\s+THRESHOLD=50\s+;;)"
        case_match = re.search(case_pattern, modified)
        if case_match:
            new_case = f"\n            {app_name}){'':>{max(0, 14 - len(app_name))}} THRESHOLD={coverage_threshold} ;;"
            modified = modified[:case_match.start()] + new_case + modified[case_match.start():]

    if dry_run:
        print(f"[dry-run] ci.yaml에 '{app_name}' 필터 추가 예정 (threshold: {coverage_threshold}%)")
        return

    _write_preserving_newlines(path, modified, newline)
    print(f"ci.yaml에 '{app_name}' 필터를 추가했습니다")


def _add_to_dispatch_options(
    path: Path,
    app_name: str,
    *,
    dry_run: bool = True,
) -> None:
    """workflow_dispatch의 app choice 옵션에 앱을 추가한다."""
    text, newline = _read_preserving_newlines(path)

    # workflow_dispatch options 블록 탐색
    # 패턴: "options:" 뒤에 나오는 앱 목록에서 마지막 항목 뒤에 삽입
    options_pattern = r"(        options:\n)((?:          - \w+\n)+)"
    match = re.search(options_pattern, text)

    if not match:
        print(f"경고: {path.name}에서 options 블록을 찾을 수 없습니다")
        return

    block_text = match.group(2)
    if app_name in block_text:
        print(f"{path.name}에 '{app_name}'이 이미 존재합니다")
        return

    new_option = f"          - {app_name}\n"
    end_pos = match.end(2)
    modified = text[:end_pos] + new_option + text[end_pos:]

    if dry_run:
        print(f"[dry-run] {path.name}에 '{app_name}' 옵션 추가 예정")
        return

    _write_preserving_newlines(path, modified, newline)
    print(f"{path.name}에 '{app_name}' 옵션을 추가했습니다")


def add_to_deploy_android(path: Path, app_name: str, *, dry_run: bool = True) -> None:
    _add_to_dispatch_options(path, app_name, dry_run=dry_run)


def add_to_deploy_ios(path: Path, app_name: str, *, dry_run: bool = True) -> None:
    _add_to_dispatch_options(path, app_name, dry_run=dry_run)


def add_to_deploy_all(path: Path, app_name: str, *, dry_run: bool = True) -> None:
    _add_to_dispatch_options(path, app_name, dry_run=dry_run)


def add_to_all_workflows(
    workflows_dir: Path,
    app_name: str,
    *,
    exclude_from_release: bool = False,
    coverage_threshold: int = 50,
    dry_run: bool = True,
) -> None:
    """5개 워크플로우 파일에 앱을 추가한다."""
    add_to_release_all(
        workflows_dir / "release-all.yaml",
        app_name,
        exclude_from_release=exclude_from_release,
        dry_run=dry_run,
    )
    add_to_ci(
        workflows_dir / "ci.yaml",
        app_name,
        coverage_threshold=coverage_threshold,
        dry_run=dry_run,
    )
    add_to_deploy_android(workflows_dir / "deploy-android.yaml", app_name, dry_run=dry_run)
    add_to_deploy_ios(workflows_dir / "deploy-ios.yaml", app_name, dry_run=dry_run)
    add_to_deploy_all(workflows_dir / "deploy-all.yaml", app_name, dry_run=dry_run)
