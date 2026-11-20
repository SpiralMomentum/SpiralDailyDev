"""신규 앱의 Fastlane 메타데이터 / store_metadata 템플릿 (순수 함수 + 쓰기 셸)."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Dict

import yaml

from common.config import REPO_ROOT, Config, default, org, path_for
from common.effects import Effects, done

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

LOCALE_FILES = {
    "subtitle.txt": "",
    "description.txt": "",
    "keywords.txt": "",
    "release_notes.txt": "Initial release",
    "support_url.txt": "",
    "privacy_url.txt": "",
}


def fastlane_files(cfg: Config, display_name: str) -> Dict[str, str]:
    """Fastlane 메타데이터 디렉토리 기준 상대 경로 -> 내용."""
    per_locale = {
        f"{locale}/{name}": content
        for locale in default(cfg, "locales")
        for name, content in {"name.txt": display_name, **LOCALE_FILES}.items()
    }
    return {
        **per_locale,
        "review_information/email_address.txt": org(cfg, "contactEmail"),
        "review_information/first_name.txt": org(cfg, "reviewFirstName"),
        "review_information/last_name.txt": org(cfg, "reviewLastName"),
        "review_information/notes.txt": "",
        "copyright.txt": org(cfg, "copyright"),
        "primary_category.txt": default(cfg, "primaryCategory"),
        "rating_config.json": json.dumps(DEFAULT_RATING_CONFIG, indent=2) + "\n",
    }


def store_metadata_yaml(cfg: Config, display_name: str) -> str:
    """tools/release/publisher.py validate_metadata()가 요구하는 필수 필드."""
    template = {
        "appName": display_name,
        "shortDescription": "",
        "fullDescription": "",
        "category": default(cfg, "primaryCategory"),
        "contact": {"email": org(cfg, "contactEmail"), "website": ""},
        "privacyPolicyUrl": "",
    }
    return yaml.dump(template, sort_keys=False, default_flow_style=False, allow_unicode=True)


def template_files(cfg: Config, app: str, display_name: str) -> Dict[str, str]:
    """저장소 기준 상대 경로 -> 내용."""
    metadata_dir = path_for(cfg, "iosMetadata", app)
    store_dir = path_for(cfg, "storeMetadata", app)
    store_yaml = store_metadata_yaml(cfg, display_name)
    return {
        **{f"{metadata_dir}/{rel}": c for rel, c in fastlane_files(cfg, display_name).items()},
        f"{path_for(cfg, 'iosScreenshots', app)}/.gitkeep": "",
        f"{store_dir}/android.yaml": store_yaml,
        f"{store_dir}/ios.yaml": store_yaml,
    }


def write_templates(effects: Effects, cfg: Config, app: str, display_name: str, repo_root: Path = REPO_ROOT) -> None:
    files = template_files(cfg, app, display_name)
    for rel, content in files.items():
        effects.write_text(repo_root / rel, content)
    done(effects, f"메타데이터 템플릿 {len(files)}개 파일 작성")
