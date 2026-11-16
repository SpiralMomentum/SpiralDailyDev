"""Android build.gradle(.kts)에 release signing config를 추가한다 (순수 텍스트 변환 + 쓰기 셸)."""

from __future__ import annotations

import re
from pathlib import Path
from typing import Optional

from common.config import Config, path_for, project_path
from common.effects import Effects, done

KTS_IMPORTS = "import java.io.FileInputStream\nimport java.util.Properties\n\n"

KTS_KEYSTORE_BLOCK = """\

val keystoreProperties = Properties().apply {{
    val keystorePropertiesFile = rootProject.file("{props}")
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

GROOVY_IMPORTS = "import java.util.Properties\n\n"

GROOVY_KEYSTORE_BLOCK = """\

def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file("{props}")
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

# flutter create 템플릿이 release 블록에 넣는 debug 서명. 남겨두면 위에 넣은 release 서명을 덮어쓴다.
FLUTTER_DEBUG_SIGNING = re.compile(
    r"^[ \t]*// TODO: Add your own signing config for the release build\.\n"
    r"|^[ \t]*// Signing with the debug keys for now.*\n"
    r'|^[ \t]*signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)[ \t]*\n'
    r"|^[ \t]*signingConfig\s+signingConfigs\.debug[ \t]*\n",
    re.MULTILINE,
)
DEFAULT_CONFIG_END = re.compile(r"    defaultConfig\s*\{[^}]*\}\s*\n", re.DOTALL)
RELEASE_BLOCK = re.compile(r"(        release\s*\{)\s*\n")
BLOCK_END = re.compile(r"^}\s*$", re.MULTILINE)
APPLY_PLUGIN = re.compile(r"^apply plugin:.*$", re.MULTILINE)


def _insert_after(text: str, match: Optional[re.Match], snippet: str) -> str:
    return text[: match.end()] + snippet + text[match.end():] if match else text


def key_properties_ref(cfg: Config, app: str) -> str:
    """rootProject(<projectPath>/android) 기준 key.properties 상대 경로."""
    depth = len(Path(project_path(cfg, app)).parts) + 1
    return "../" * depth + f"{path_for(cfg, 'signing', app)}/key.properties"


def patch_kts(text: str, props: str) -> Optional[str]:
    """이미 패치돼 있으면 None."""
    if "keystoreProperties" in text:
        return None
    t = FLUTTER_DEBUG_SIGNING.sub("", text)
    t = t if "import java.io.FileInputStream" in t else KTS_IMPORTS + t
    t = _insert_after(t, BLOCK_END.search(t), KTS_KEYSTORE_BLOCK.format(props=props))
    t = _insert_after(t, DEFAULT_CONFIG_END.search(t), "\n" + KTS_SIGNING_CONFIGS)
    return _insert_after(t, RELEASE_BLOCK.search(t), KTS_RELEASE_SIGNING + "\n")


def patch_groovy(text: str, props: str) -> Optional[str]:
    if "keystoreProperties" in text:
        return None
    t = FLUTTER_DEBUG_SIGNING.sub("", text)
    t = t if "import java.util.Properties" in t else GROOVY_IMPORTS + t
    applies = list(APPLY_PLUGIN.finditer(t))
    t = _insert_after(t, applies[-1] if applies else BLOCK_END.search(t), GROOVY_KEYSTORE_BLOCK.format(props=props))
    t = _insert_after(t, DEFAULT_CONFIG_END.search(t), "\n" + GROOVY_SIGNING_CONFIGS)
    return _insert_after(t, RELEASE_BLOCK.search(t), GROOVY_RELEASE_SIGNING + "\n")


def patch_gradle(effects: Effects, cfg: Config, repo_root: Path, app: str) -> None:
    app_dir = repo_root / project_path(cfg, app) / "android" / "app"
    props = key_properties_ref(cfg, app)
    for name, patch in (("build.gradle.kts", patch_kts), ("build.gradle", patch_groovy)):
        path = app_dir / name
        if effects.exists(path):
            patched = patch(effects.read_text(path), props)
            if patched is None:
                effects.log(f"{name}에 signing config가 이미 존재합니다. 건너뜁니다.")
            else:
                effects.write_text(path, patched)
                done(effects, f"{path.relative_to(repo_root)} signing config 패치 완료")
            return
    effects.log(f"경고: {app_dir}에 build.gradle.kts 또는 build.gradle이 없습니다")
