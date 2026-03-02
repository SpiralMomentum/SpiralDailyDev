"""Fastlane 메타데이터 및 store_metadata 템플릿을 생성한다."""

from __future__ import annotations

import json
from pathlib import Path

# App Store 기본 rating config (전 연령)
DEFAULT_RATING_CONFIG = {
    "alcoholTobaccoOrDrugUseOrReferences": "NONE",
    "contests": "NONE",
    "gamblingSimulated": "NONE",
    "gunsOrOtherWeapons": "NONE",
    "horrorOrFearThemes": "NONE",
    "matureOrSuggestiveThemes": "NONE",
    "medicalOrTreatmentInformation": "NONE",
    "profanityOrCrudeHumor": "NONE",
    "sexualContentGraphicAndNudity": "NONE",
    "sexualContentOrNudity": "NONE",
    "violenceCartoonOrFantasy": "NONE",
    "violenceRealistic": "NONE",
    "violenceRealisticProlongedGraphicOrSadistic": "NONE",
    "gambling": False,
    "lootBox": False,
    "unrestrictedWebAccess": False,
    "ageAssurance": False,
    "advertising": False,
    "healthOrWellnessTopics": False,
    "messagingAndChat": False,
    "parentalControls": False,
    "userGeneratedContent": False,
}

# publisher.py의 validate_metadata()가 요구하는 필수 필드
STORE_METADATA_TEMPLATE = {
    "appName": "",
    "shortDescription": "",
    "fullDescription": "",
    "category": "LIFESTYLE",
    "contact": {
        "email": "spiraldailydev@gmail.com",
        "website": "",
    },
    "privacyPolicyUrl": "",
}


def _write_file(path: Path, content: str, *, dry_run: bool) -> None:
    if dry_run:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def setup_fastlane_metadata(
    repo_root: Path,
    app_name: str,
    display_name: str,
    *,
    dry_run: bool = True,
) -> None:
    """Fastlane 메타데이터 디렉토리를 생성한다."""
    base = repo_root / "fastlane" / "metadata" / app_name

    if dry_run:
        print(f"[dry-run] fastlane/metadata/{app_name}/ 디렉토리 생성 예정")
        print(f"  en-US/, ko/ 로케일 메타데이터")
        print(f"  review_information/")
        print(f"  copyright.txt, primary_category.txt, rating_config.json")
        return

    # en-US 로케일
    for locale in ("en-US", "ko"):
        locale_dir = base / locale
        _write_file(locale_dir / "name.txt", display_name, dry_run=False)
        _write_file(locale_dir / "subtitle.txt", "", dry_run=False)
        _write_file(locale_dir / "description.txt", "", dry_run=False)
        _write_file(locale_dir / "keywords.txt", "", dry_run=False)
        _write_file(locale_dir / "release_notes.txt", "Initial release", dry_run=False)
        _write_file(locale_dir / "support_url.txt", "", dry_run=False)
        _write_file(locale_dir / "privacy_url.txt", "", dry_run=False)

    # review_information
    review_dir = base / "review_information"
    _write_file(review_dir / "email_address.txt", "spiraldailydev@gmail.com", dry_run=False)
    _write_file(review_dir / "first_name.txt", "Spiral", dry_run=False)
    _write_file(review_dir / "last_name.txt", "Dev", dry_run=False)
    _write_file(review_dir / "notes.txt", "", dry_run=False)

    # 기타 메타데이터
    _write_file(base / "copyright.txt", "2026 Spiral Dev", dry_run=False)
    _write_file(base / "primary_category.txt", "LIFESTYLE", dry_run=False)
    _write_file(
        base / "rating_config.json",
        json.dumps(DEFAULT_RATING_CONFIG, indent=2) + "\n",
        dry_run=False,
    )

    print(f"fastlane/metadata/{app_name}/ 디렉토리를 생성했습니다")


def setup_screenshots_dir(
    repo_root: Path,
    app_name: str,
    *,
    dry_run: bool = True,
) -> None:
    """Fastlane 스크린샷 디렉토리를 생성한다."""
    screenshots_dir = repo_root / "fastlane" / "screenshots" / app_name

    if dry_run:
        print(f"[dry-run] fastlane/screenshots/{app_name}/ 디렉토리 생성 예정")
        return

    screenshots_dir.mkdir(parents=True, exist_ok=True)
    gitkeep = screenshots_dir / ".gitkeep"
    if not gitkeep.exists():
        gitkeep.touch()
    print(f"fastlane/screenshots/{app_name}/ 디렉토리를 생성했습니다")


def setup_store_metadata(
    repo_root: Path,
    app_name: str,
    display_name: str,
    *,
    dry_run: bool = True,
) -> None:
    """store_metadata/{app}/ 디렉토리에 android.yaml, ios.yaml을 생성한다."""
    import yaml

    base = repo_root / "store_metadata" / app_name

    template = STORE_METADATA_TEMPLATE.copy()
    template["appName"] = display_name

    if dry_run:
        print(f"[dry-run] store_metadata/{app_name}/android.yaml 생성 예정")
        print(f"[dry-run] store_metadata/{app_name}/ios.yaml 생성 예정")
        return

    base.mkdir(parents=True, exist_ok=True)

    for platform in ("android", "ios"):
        path = base / f"{platform}.yaml"
        content = yaml.dump(template, sort_keys=False, default_flow_style=False, allow_unicode=True)
        path.write_text(content, encoding="utf-8")

    print(f"store_metadata/{app_name}/ 메타데이터를 생성했습니다")


def setup_all_metadata(
    repo_root: Path,
    app_name: str,
    display_name: str,
    *,
    dry_run: bool = True,
) -> None:
    """모든 메타데이터를 생성한다."""
    setup_fastlane_metadata(repo_root, app_name, display_name, dry_run=dry_run)
    setup_screenshots_dir(repo_root, app_name, dry_run=dry_run)
    setup_store_metadata(repo_root, app_name, display_name, dry_run=dry_run)
