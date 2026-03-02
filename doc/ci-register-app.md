# CI/CD 파이프라인 도구

---

## 1. 개요

### 아키텍처

`release.yaml`이 **단일 진실 공급원(Single Source of Truth)**이다. 앱 목록, 배포 제외 여부, 커버리지 임계값, gitignored 파일 등 모든 CI/CD 설정이 이 파일에 정의된다.

```
release.yaml (단일 진실 공급원)
    │
    ├── tools/pipeline/               CLI 도구 (직접 실행)
    │     ├── pipeline.py               빌드/테스트/배포 통합 인터페이스
    │     ├── add_app.py                새 앱 등록
    │     ├── list_apps.py              CI matrix용 앱 목록 JSON 출력
    │     ├── detect_changes.py         paths-filter YAML 출력
    │     ├── verify_coverage.py        커버리지 검증
    │     └── check_app_size.sh         APK/IPA 크기 검사
    │
    └── tools/pipeline/steps/         내부 모듈 (CLI에서 호출)
          ├── prepare_build.py          빌드 전 gitignored 파일 생성
          ├── add_app_config.py         release.yaml 앱 항목 추가
          ├── setup_signing.py          Android keystore 생성 + GitHub Secrets
          ├── setup_metadata.py         Fastlane/store 메타데이터 템플릿
          ├── patch_gradle.py           build.gradle signing config 패치
          ├── register_store.py         App Store 등록 + Play Store 가이드
          └── name_utils.py             snake_case <-> camelCase 변환
```

CI 워크플로우와 로컬 모두 **동일한 명령**으로 빌드/배포한다:

```bash
# 로컬 또는 CI에서 동일하게 실행
python3 tools/pipeline/pipeline.py deploy --app daily_memo --platform android --target production
```

### 호출 계층

CLI 도구와 내부 모듈은 다음과 같은 호출 관계를 갖는다:

```
pipeline.py
  └── steps/prepare_build.py        prepare/test/build/deploy 시 gitignored 파일 생성

add_app.py
  ├── steps/add_app_config.py       [1/5] release.yaml 편집
  ├── steps/setup_signing.py        [2/5] keystore 생성
  ├── steps/setup_metadata.py       [3/5] 메타데이터 템플릿
  ├── steps/patch_gradle.py         [4/5] build.gradle 패치
  └── steps/register_store.py       [5/5] 스토어 등록

list_apps.py                        독립 실행 (release.yaml만 읽음)
detect_changes.py                   독립 실행 (release.yaml만 읽음)
verify_coverage.py                  독립 실행 (release.yaml + lcov.info)
```

### 도구 목록

**CLI 도구** — `tools/pipeline/` (직접 실행)

| 파일 | 역할 |
|------|------|
| `pipeline.py` | 빌드/테스트/배포 통합 인터페이스. CI와 로컬 모두 이 스크립트를 통해 실행한다 |
| `add_app.py` | 새 Flutter 앱을 CI/CD 파이프라인에 등록한다. 5단계를 순차 실행한다 |
| `list_apps.py` | release.yaml에서 앱 목록을 읽어 JSON으로 출력한다. CI matrix 생성용 |
| `detect_changes.py` | release.yaml의 projectPath로 dorny/paths-filter YAML을 생성한다 |
| `verify_coverage.py` | lcov.info를 파싱하고 release.yaml의 coverageThreshold와 비교한다 |
| `check_app_size.sh` | 빌드 산출물(APK/IPA)의 크기를 검사한다 |

**내부 모듈** — `tools/pipeline/steps/` (CLI에서 import)

| 파일 | 호출하는 CLI | 역할 |
|------|------------|------|
| `prepare_build.py` | `pipeline.py` | release.yaml `ci.gitIgnoredFiles` 설정에 따라 빌드 전 파일을 생성한다 |
| `add_app_config.py` | `add_app.py` | release.yaml에 앱 항목을 추가한다 (ci 섹션 포함) |
| `setup_signing.py` | `add_app.py` | Android keystore를 생성하고 GitHub Secrets 등록을 안내한다 |
| `setup_metadata.py` | `add_app.py` | Fastlane/store 메타데이터 디렉토리와 템플릿 파일을 생성한다 |
| `patch_gradle.py` | `add_app.py` | build.gradle에 signing config 블록을 삽입한다 |
| `register_store.py` | `add_app.py` | App Store Connect에 Bundle ID를 등록하고 Play Store 가이드를 출력한다 |
| `name_utils.py` | `add_app.py` 외 | snake_case/camelCase/PascalCase 변환과 앱 이름 유효성 검증 |

---

## 2. pipeline.py 사용법

### prepare: 빌드 전 준비

release.yaml `ci.gitIgnoredFiles` 설정에 따라 빌드에 필요한 파일을 생성한다.

```bash
python3 tools/pipeline/pipeline.py prepare --app daily_memo
# [prepare] daily_memo: gitignored 파일 생성
#   -> apps/daily_memo/android/app/google-services.json (더미, GOOGLE_SERVICES_JSON_DAILY_MEMO 미설정)

python3 tools/pipeline/pipeline.py prepare --app film_archive
# [prepare] film_archive: gitignored 파일 생성
#   -> apps/film_archive/lib/tmdb_api_key.dart (content)
```

### test: 테스트 실행

빌드 준비 + flutter test를 실행한다.

```bash
python3 tools/pipeline/pipeline.py test --app daily_memo
python3 tools/pipeline/pipeline.py test --app daily_memo --coverage
```

### build: 앱 빌드

```bash
python3 tools/pipeline/pipeline.py build --app daily_memo --platform android
python3 tools/pipeline/pipeline.py build --app daily_memo --platform ios
```

### deploy: 스토어 배포

빌드 준비 + Fastlane 레인 호출.

```bash
python3 tools/pipeline/pipeline.py deploy --app daily_memo --platform android --target production
python3 tools/pipeline/pipeline.py deploy --app daily_memo --platform android --target internal
python3 tools/pipeline/pipeline.py deploy --app daily_memo --platform ios --target appstore
python3 tools/pipeline/pipeline.py deploy --app daily_memo --platform ios --target testflight
```

`--dry-run` 플래그로 실행 예정 명령만 확인할 수 있다:

```bash
python3 tools/pipeline/pipeline.py deploy --app daily_memo --platform android --target production --dry-run
# [deploy] daily_memo: 빌드 준비
# [deploy] daily_memo: android production 배포
#   [dry-run] bundle exec fastlane android deploy_production app:daily_memo
```

내부적으로 Fastlane을 호출하지만, 다른 도구로 교체하려면 `release.yaml`의 `pipeline.fastlaneBinary`와 `pipeline.py` 내부만 수정하면 된다.

---

## 3. 새 앱 등록 (add_app.py)

### 사전 조건

- Python 3.10 이상
- `pyyaml` 패키지 (`pip install pyyaml`)
- `apps/{app_name}/` 디렉토리가 존재하고 `pubspec.yaml`을 포함해야 한다
- JDK (keystore 생성 시 `keytool` 필요)
- Bundler + Fastlane (스토어 등록 시 필요)

### 기본 사용

```bash
python3 tools/pipeline/add_app.py \
  --app my_new_app \
  --display-name "My New App"
```

### dry-run

```bash
python3 tools/pipeline/add_app.py \
  --app my_new_app \
  --display-name "My New App" \
  --dry-run
```

### 부분 실행

```bash
python3 tools/pipeline/add_app.py \
  --app my_new_app \
  --display-name "My New App" \
  --skip-store \
  --skip-signing
```

### 릴리즈 배포 제외

```bash
python3 tools/pipeline/add_app.py \
  --app my_prototype_app \
  --display-name "My Prototype" \
  --exclude-from-release
```

### CLI 레퍼런스

| 옵션 | 기본값 | 설명 |
|------|--------|------|
| `--app` (필수) | - | snake_case 앱 이름 |
| `--display-name` (필수) | - | 앱 표시 이름 |
| `--app-id` | `com.spiraldev.{app_name}` | Android application ID |
| `--ios-bundle-id` | `com.spiraldev.{camelCase}` | iOS bundle ID |
| `--skip-store` | false | 스토어 등록 건너뛰기 |
| `--skip-signing` | false | keystore/match 생성 건너뛰기 |
| `--skip-gradle` | false | build.gradle 패치 건너뛰기 |
| `--exclude-from-release` | false | 배포 matrix 제외 (ci.excludeFromRelease) |
| `--coverage-threshold` | 50 | CI 커버리지 임계값 (ci.coverageThreshold) |
| `--dry-run` | false | 실제 변경 없이 예정 작업만 출력 |

### 실행 단계

| 단계 | 내부 모듈 | 설명 |
|------|----------|------|
| [1/5] release.yaml 편집 | `steps/add_app_config.py` | ci 섹션 포함 앱 항목 추가 |
| [2/5] Android signing | `steps/setup_signing.py` | keystore 생성 + GitHub Secrets |
| [3/5] 메타데이터 템플릿 | `steps/setup_metadata.py` | Fastlane + store_metadata 생성 |
| [4/5] build.gradle 패치 | `steps/patch_gradle.py` | signing config 추가 |
| [5/5] 스토어 등록 | `steps/register_store.py` | Bundle ID + match + 가이드 |

기존 6단계에서 5단계로 축소: 워크플로우 직접 편집이 불필요해졌다. release.yaml에 앱을 추가하면 CI 워크플로우가 자동으로 인식한다.

---

## 4. release.yaml ci 섹션

각 앱은 `ci` 섹션으로 CI/CD 동작을 제어한다:

```yaml
apps:
  daily_memo:
    ci:
      coverageThreshold: 70        # 기본값: 50
      integrationTest: true         # 통합 테스트 실행 여부
      gitIgnoredFiles:              # 빌드 전 자동 생성할 파일
        - path: android/app/google-services.json
          secret: GOOGLE_SERVICES_JSON_DAILY_MEMO
  film_archive:
    ci:
      coverageThreshold: 40
      gitIgnoredFiles:
        - path: lib/tmdb_api_key.dart
          content: "const tmdbApiKey = String.fromEnvironment('TMDB_API_KEY', defaultValue: '');"
  spiral_trade_show:
    ci:
      excludeFromRelease: true      # 배포 matrix에서 제외
```

`ci` 섹션 생략 시 기본값: `excludeFromRelease=false`, `coverageThreshold=50`.

### gitIgnoredFiles 옵션

| 필드 | 설명 |
|------|------|
| `path` | 앱 프로젝트 디렉토리 기준 상대 경로 |
| `secret` | 환경변수 이름. CI에서는 GitHub Secrets에서 주입, 로컬에서는 미설정 시 더미 생성 |
| `content` | 파일 내용을 직접 지정 |

---

## 5. CI 워크플로우 동작 방식

### release-all.yaml (릴리즈 배포)

```
release/* 태그 push
    -> setup: list_apps.py -> 앱 목록 JSON
    -> test: 전체 앱 (all-apps matrix)
    -> deploy-android: 배포 앱 (deploy-apps matrix)
    -> deploy-ios: 배포 앱 (deploy-apps matrix)
```

앱 목록은 `tools/pipeline/list_apps.py`가 release.yaml에서 동적 생성한다. 하드코딩된 matrix가 없다.

### ci.yaml (PR 검증)

```
PR/push to main/develop
    -> detect-changes: detect_changes.py -> paths-filter 설정 생성
    -> analyze-and-test: 변경된 앱만 (pipeline.py prepare/test + verify_coverage.py)
```

### deploy-*.yaml (수동 배포)

앱 이름을 자유 텍스트(string)로 입력. release.yaml에 존재하는지 런타임 검증한다.

### 배포 호출 흐름

Android production 배포 시 실행되는 전체 호출 순서:

```
pipeline.py deploy --app film_archive --platform android --target production
  │
  ├── release.yaml 로드 → 앱 설정 읽기
  ├── steps/prepare_build.py → gitignored 파일 생성
  │     └── ci.gitIgnoredFiles 항목별 파일 쓰기
  └── subprocess: bundle exec fastlane android deploy_production app:film_archive
        │
        └── Fastfile android deploy_production
              ├── flutter build appbundle --release
              └── upload_to_play_store (aab → Play Store)
```

iOS appstore 배포 시:

```
pipeline.py deploy --app film_archive --platform ios --target appstore
  │
  ├── release.yaml 로드 → 앱 설정 읽기
  ├── steps/prepare_build.py → gitignored 파일 생성
  └── subprocess: bundle exec fastlane ios deploy_appstore app:film_archive
        │
        └── Fastfile ios deploy_appstore
              ├── flutter build ios --no-codesign
              ├── match(type: "appstore") → 인증서/프로비저닝 다운로드
              ├── update_code_signing_settings → Runner 타겟에 signing 적용
              ├── build_app(workspace: .xcworkspace) → IPA 빌드
              └── upload_to_app_store → App Store Connect 업로드
```

---

## 6. ASC API Key 크레덴셜

| 항목 | 값 |
|------|-----|
| Key ID | `HZ89QN4W7U` |
| Issuer ID | `f42e9e12-3482-46c6-9e4d-d4e11d33de60` |
| 역할 | 관리자 (Admin) |
| .p8 파일 | `signing/asc/AuthKey_HZ89QN4W7U.p8` (gitignored) |
| Team ID | `BXMP99D98Z` |

로컬 환경변수:

```bash
export ASC_KEY_ID="HZ89QN4W7U"
export ASC_ISSUER_ID="f42e9e12-3482-46c6-9e4d-d4e11d33de60"
export ASC_KEY_FILEPATH="signing/asc/AuthKey_HZ89QN4W7U.p8"
```

---

## 7. 등록 후 체크리스트

- [ ] `store_metadata/{app}/android.yaml` 필수 필드 채우기
- [ ] `store_metadata/{app}/ios.yaml` 필수 필드 채우기
- [ ] `fastlane/metadata/{app}/en-US/` 로케일 메타데이터 채우기
- [ ] `fastlane/metadata/{app}/ko/` 로케일 메타데이터 채우기
- [ ] GitHub repository Settings > Secrets에 시크릿 등록
- [ ] Google Play Console에서 앱 수동 생성 (Android)
- [ ] PR을 올려서 CI 파이프라인 동작 확인
- [ ] `python3 tools/pipeline/pipeline.py test --app {app}` 로컬 테스트 확인
