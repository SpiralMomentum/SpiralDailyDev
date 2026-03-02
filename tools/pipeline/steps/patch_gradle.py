"""Android build.gradle.kts/.gradle에 signing config를 추가한다."""

from __future__ import annotations

import re
from pathlib import Path

# Kotlin DSL (build.gradle.kts) 패치 템플릿
KTS_IMPORTS = """\
import java.io.FileInputStream
import java.util.Properties

"""

KTS_KEYSTORE_BLOCK = """\

val keystoreProperties = Properties().apply {{
    val keystorePropertiesFile = rootProject.file("../../../signing/{app_name}/android/key.properties")
    if (keystorePropertiesFile.exists()) {{
        load(FileInputStream(keystorePropertiesFile))
    }}
}}

"""

KTS_SIGNING_CONFIGS = """\
    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties["storeFile"] as String?
            if (storeFilePath != null) {
                storeFile = file(storeFilePath)
            }
            storePassword = keystoreProperties["storePassword"] as String?
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
        }
    }

"""

KTS_RELEASE_SIGNING = """\
            signingConfig = if (keystoreProperties["storeFile"] != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }"""

# Groovy DSL (build.gradle) 패치 템플릿
GROOVY_IMPORTS = """\
import java.util.Properties

"""

GROOVY_KEYSTORE_BLOCK = """\

def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file("../../../signing/{app_name}/android/key.properties")
if (keystorePropertiesFile.exists()) {{
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}}

"""

GROOVY_SIGNING_CONFIGS = """\
    signingConfigs {
        release {
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
        }
    }

"""

GROOVY_RELEASE_SIGNING = """\
            signingConfig keystoreProperties['storeFile'] ? signingConfigs.release : signingConfigs.debug"""


def patch_gradle(
    repo_root: Path,
    app_name: str,
    *,
    dry_run: bool = True,
) -> None:
    """build.gradle.kts 또는 build.gradle에 signing config를 추가한다."""
    app_dir = repo_root / "apps" / app_name / "android" / "app"
    kts_path = app_dir / "build.gradle.kts"
    groovy_path = app_dir / "build.gradle"

    if kts_path.exists():
        _patch_kts(kts_path, app_name, dry_run=dry_run)
    elif groovy_path.exists():
        _patch_groovy(groovy_path, app_name, dry_run=dry_run)
    else:
        print(f"경고: {app_dir}에 build.gradle.kts 또는 build.gradle을 찾을 수 없습니다")


def _patch_kts(path: Path, app_name: str, *, dry_run: bool) -> None:
    """Kotlin DSL build.gradle.kts에 signing config를 패치한다."""
    text = path.read_text(encoding="utf-8")

    # 멱등성: keystoreProperties가 이미 존재하면 스킵
    if "keystoreProperties" in text:
        print(f"{path.name}에 signing config가 이미 존재합니다. 스킵합니다.")
        return

    if dry_run:
        print(f"[dry-run] {path} signing config 패치 예정 (Kotlin DSL)")
        return

    modified = text

    # 1) import 추가
    if "import java.io.FileInputStream" not in modified:
        modified = KTS_IMPORTS + modified

    # 2) keystoreProperties 블록 추가 (plugins { } 블록 뒤)
    plugins_end = re.search(r"^}\s*$", modified, re.MULTILINE)
    if plugins_end:
        insert_pos = plugins_end.end()
        modified = (
            modified[:insert_pos]
            + KTS_KEYSTORE_BLOCK.format(app_name=app_name)
            + modified[insert_pos:]
        )

    # 3) signingConfigs 블록 추가 (android { 블록 내, defaultConfig 뒤)
    default_config_end = re.search(r"    defaultConfig\s*\{[^}]*\}\s*\n", modified, re.DOTALL)
    if default_config_end:
        insert_pos = default_config_end.end()
        modified = modified[:insert_pos] + "\n" + KTS_SIGNING_CONFIGS + modified[insert_pos:]

    # 4) buildTypes.release에 signingConfig 추가
    # release 블록에서 isMinifyEnabled 또는 isShrinkResources 앞에 삽입
    release_block = re.search(r"(        release\s*\{)\s*\n", modified)
    if release_block:
        insert_pos = release_block.end()
        modified = modified[:insert_pos] + KTS_RELEASE_SIGNING + "\n" + modified[insert_pos:]

    path.write_text(modified, encoding="utf-8")
    print(f"{path} signing config를 패치했습니다 (Kotlin DSL)")


def _patch_groovy(path: Path, app_name: str, *, dry_run: bool) -> None:
    """Groovy DSL build.gradle에 signing config를 패치한다."""
    text = path.read_text(encoding="utf-8")

    if "keystoreProperties" in text:
        print(f"{path.name}에 signing config가 이미 존재합니다. 스킵합니다.")
        return

    if dry_run:
        print(f"[dry-run] {path} signing config 패치 예정 (Groovy DSL)")
        return

    modified = text

    # 1) import 추가
    if "import java.util.Properties" not in modified:
        modified = GROOVY_IMPORTS + modified

    # 2) keystoreProperties 블록 추가
    # "apply plugin" 또는 plugins 블록 뒤에 삽입
    plugin_match = re.search(r"^(apply plugin:.*|}\s*)$", modified, re.MULTILINE)
    if plugin_match:
        # 마지막 apply plugin 줄 또는 plugins 블록 종료 뒤
        apply_lines = list(re.finditer(r"^apply plugin:.*$", modified, re.MULTILINE))
        if apply_lines:
            insert_pos = apply_lines[-1].end()
        else:
            plugins_end = re.search(r"^}\s*$", modified, re.MULTILINE)
            insert_pos = plugins_end.end() if plugins_end else 0
        modified = (
            modified[:insert_pos]
            + GROOVY_KEYSTORE_BLOCK.format(app_name=app_name)
            + modified[insert_pos:]
        )

    # 3) signingConfigs 블록 추가
    default_config_end = re.search(r"    defaultConfig\s*\{[^}]*\}\s*\n", modified, re.DOTALL)
    if default_config_end:
        insert_pos = default_config_end.end()
        modified = modified[:insert_pos] + "\n" + GROOVY_SIGNING_CONFIGS + modified[insert_pos:]

    # 4) release 블록에 signingConfig 추가
    release_block = re.search(r"(        release\s*\{)\s*\n", modified)
    if release_block:
        insert_pos = release_block.end()
        modified = modified[:insert_pos] + GROOVY_RELEASE_SIGNING + "\n" + modified[insert_pos:]

    path.write_text(modified, encoding="utf-8")
    print(f"{path} signing config를 패치했습니다 (Groovy DSL)")
