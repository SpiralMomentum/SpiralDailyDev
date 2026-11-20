"""App Store 신규 등록: Spaceship으로 Bundle ID 등록 + 앱 존재 확인, match로 프로비저닝 프로필 생성."""

from __future__ import annotations

import json
import os
import tempfile
from contextlib import contextmanager
from pathlib import Path
from typing import Callable, Dict, Iterator, List, Mapping, Optional

from common.effects import Effects

SPACESHIP_SCRIPT = """
require "spaceship"
require "json"

api_key_data = JSON.parse(File.read(ENV.fetch("ASC_API_KEY_JSON")))
Spaceship::ConnectAPI.token = Spaceship::ConnectAPI::Token.create(
  key_id: api_key_data["key_id"],
  issuer_id: api_key_data["issuer_id"],
  key: api_key_data["key"],
)

bundle_id = ENV.fetch("BUNDLE_ID")
if Spaceship::ConnectAPI::BundleId.find(bundle_id)
  puts "BUNDLE_ID_EXISTS"
else
  Spaceship::ConnectAPI::BundleId.create(
    name: ENV.fetch("APP_DISPLAY_NAME"),
    identifier: bundle_id,
    platform: Spaceship::ConnectAPI::BundleIdPlatform::IOS,
  )
  puts "BUNDLE_ID_CREATED"
end

puts(Spaceship::ConnectAPI::App.find(bundle_id) ? "APP_EXISTS" : "APP_NOT_FOUND")
"""


def asc_api_key(
    env: Mapping[str, str],
    exists: Callable[[Path], bool],
    read_text: Callable[[Path], str],
) -> Optional[Dict[str, object]]:
    """ASC_KEY_ID, ASC_ISSUER_ID + (ASC_KEY_FILEPATH 또는 ASC_KEY_CONTENT)로 Fastlane api_key 데이터를 만든다."""
    key_id, issuer_id = env.get("ASC_KEY_ID"), env.get("ASC_ISSUER_ID")
    if not key_id or not issuer_id:
        return None
    filepath = env.get("ASC_KEY_FILEPATH")
    if filepath and exists(Path(filepath)):
        key = read_text(Path(filepath))
    elif env.get("ASC_KEY_CONTENT"):
        key = env["ASC_KEY_CONTENT"]
    else:
        return None
    return {"key_id": key_id, "issuer_id": issuer_id, "key": key, "in_house": False}


def spaceship_messages(stdout: str, bundle_id: str, display_name: str) -> List[str]:
    messages = {
        "BUNDLE_ID_CREATED": [f"  Bundle ID '{bundle_id}' 등록 완료"],
        "BUNDLE_ID_EXISTS": [f"  Bundle ID '{bundle_id}' 이미 등록됨"],
        "APP_EXISTS": ["  App Store Connect에 앱이 이미 존재합니다"],
        "APP_NOT_FOUND": [
            "  App Store Connect에 앱을 수동으로 생성하세요:",
            "    1. https://appstoreconnect.apple.com/apps 접속",
            "    2. '+' > 'New App' 클릭",
            f"    3. Bundle ID: {bundle_id} (드롭다운에서 선택)",
            f"    4. Name: {display_name}, SKU: {bundle_id}",
        ],
    }
    return [m for line in stdout.splitlines() for m in messages.get(line.strip(), [])]


def first_error_line(stderr: str) -> str:
    return next((l.strip() for l in stderr.splitlines() if "error" in l.lower()), "Spaceship 실행 실패")


def match_error_messages(stderr: str) -> List[str]:
    if "Invalid password" in stderr or "bad decrypt" in stderr:
        return ["  경고: MATCH_PASSWORD가 필요합니다. CI에서 자동 처리됩니다."]
    return [f"  경고: {l.strip()}" for l in stderr.splitlines()[-3:] if l.strip()]


@contextmanager
def _api_key_file(effects: Effects, data: Mapping[str, object]) -> Iterator[Path]:
    """비밀키가 담기므로 0600 임시 파일로 쓰고 끝나면 지운다. dry-run에서는 만들지 않는다."""
    if effects.dry_run:
        yield Path("<asc_api_key.json>")
        return
    fd, name = tempfile.mkstemp(suffix=".json", prefix="asc_api_key_")
    try:
        with os.fdopen(fd, "w") as f:
            json.dump(data, f)
        yield Path(name)
    finally:
        os.unlink(name)


def register_app_store(effects: Effects, repo_root: Path, bundle_id: str, display_name: str) -> Optional[str]:
    """실패하면 이유를, 성공하면 None을 돌려준다."""
    effects.log("\n--- App Store 등록 ---")
    key = asc_api_key(effects.env, effects.exists, effects.read_text)
    if not key:
        effects.log("환경변수 미설정: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_FILEPATH (또는 ASC_KEY_CONTENT)")
        return "ASC API 키 환경변수 미설정"
    if not effects.which("bundle"):
        effects.log("경고: bundler를 찾을 수 없습니다.")
        return "bundler 없음"

    with _api_key_file(effects, key) as key_path:
        r = effects.run(
            ["bundle", "exec", "ruby", "-e", SPACESHIP_SCRIPT],
            cwd=repo_root,
            env={"ASC_API_KEY_JSON": str(key_path), "BUNDLE_ID": bundle_id, "APP_DISPLAY_NAME": display_name},
            capture=True,
            label=f"spaceship: Bundle ID '{bundle_id}' 등록 + 앱 확인",
        )
        if not r.ok:
            reason = first_error_line(r.stderr)
            effects.log(f"  경고: {reason}")
            return reason
        for line in spaceship_messages(r.stdout, bundle_id, display_name):
            effects.log(line)

        effects.log("  match 실행 중...")
        r = effects.run(
            ["bundle", "exec", "fastlane", "match", "appstore", "-a", bundle_id, "--api_key_path", str(key_path)],
            cwd=repo_root,
            capture=True,
            label=f"match appstore -a {bundle_id}",
        )
        for line in ["  프로비저닝 프로필 생성 완료"] if r.ok else match_error_messages(r.stderr):
            effects.log(line)
        return None if r.ok else "match 프로비저닝 실패"
