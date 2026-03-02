# CI/CD 파이프라인 앱 등록 도구

---

## 1. 개요

`tools/ci/register_app.py`는 monorepo에 새 Flutter 앱을 추가할 때 CI/CD 파이프라인 등록에 필요한 반복 작업을 자동화하는 CLI 도구다.

기존에는 새 앱을 등록하려면 6개 이상의 YAML 파일을 수동 편집하고, signing 디렉토리 생성, 메타데이터 템플릿 작성 등을 일일이 수행해야 했다. 이 도구는 한 줄의 명령으로 모든 등록 과정을 완료한다.

### 자동화 범위

| 단계 | 수동 작업 | 자동화 |
|------|-----------|--------|
| release.yaml 편집 | 앱 항목 직접 추가 (약 20줄) | `config_editor.py` |
| GitHub Actions 5개 파일 편집 | 파일별 matrix/options에 앱 추가 | `workflow_editor.py` |
| Android keystore 생성 | keytool 실행 + key.properties 작성 | `signing_setup.py` |
| Fastlane 메타데이터 템플릿 | 20개 이상 파일 수동 생성 | `metadata_setup.py` |
| build.gradle signing 설정 | Kotlin/Groovy DSL 패치 | `gradle_patcher.py` |
| App Store / Play Store 등록 | fastlane produce + match / 수동 | `store_register.py` |

---

## 2. 사전 조건

- Python 3.10 이상
- `pyyaml` 패키지 (`pip install pyyaml`)
- `apps/{app_name}/` 디렉토리가 존재하고 `pubspec.yaml`을 포함해야 한다
- JDK (keystore 생성 시 `keytool` 필요)
- Bundler + Fastlane (스토어 등록 시 필요)

---

## 3. 사용법

### 기본 사용

```bash
python3 tools/ci/register_app.py \
  --app my_new_app \
  --display-name "My New App"
```

### dry-run (미리보기)

실제 파일 변경 없이 어떤 작업이 수행될지 확인한다.

```bash
python3 tools/ci/register_app.py \
  --app my_new_app \
  --display-name "My New App" \
  --dry-run
```

### 부분 실행

특정 단계를 건너뛰려면 `--skip-*` 플래그를 사용한다.

```bash
# 스토어 등록과 signing 생성을 건너뛰고 CI/CD 설정만 수행
python3 tools/ci/register_app.py \
  --app my_new_app \
  --display-name "My New App" \
  --skip-store \
  --skip-signing
```

### 릴리즈 배포 제외

Play Store/App Store에 미등록된 앱은 `--exclude-from-release`로 배포 matrix에서 제외한다. 테스트 matrix에는 포함된다.

```bash
python3 tools/ci/register_app.py \
  --app my_prototype_app \
  --display-name "My Prototype" \
  --exclude-from-release
```

### 커스텀 커버리지 임계값

CI에서 적용할 코드 커버리지 임계값을 지정한다. 기본값은 50%.

```bash
python3 tools/ci/register_app.py \
  --app my_new_app \
  --display-name "My New App" \
  --coverage-threshold 30
```

---

## 4. CLI 레퍼런스

```
python3 tools/ci/register_app.py [OPTIONS]
```

### 필수 옵션

| 옵션 | 설명 | 예시 |
|------|------|------|
| `--app` | snake_case 앱 이름 | `--app exchange_rate_calculator` |
| `--display-name` | 앱 표시 이름 | `--display-name "Exchange Rate Calculator"` |

### 선택 옵션

| 옵션 | 기본값 | 설명 |
|------|--------|------|
| `--app-id` | `com.spiraldev.{app_name}` | Android application ID |
| `--ios-bundle-id` | `com.spiraldev.{camelCase}` | iOS bundle ID |
| `--skip-store` | false | 스토어 등록 건너뛰기 |
| `--skip-signing` | false | keystore/match 생성 건너뛰기 |
| `--skip-gradle` | false | build.gradle 패치 건너뛰기 |
| `--exclude-from-release` | false | release-all.yaml 배포 matrix 제외 |
| `--coverage-threshold` | 50 | CI 커버리지 임계값 (%) |
| `--dry-run` | false | 실제 변경 없이 예정 작업만 출력 |

### 기본값 규칙

| 항목 | 변환 규칙 | 예시 |
|------|-----------|------|
| `--app-id` | `com.spiraldev.{snake_case}` | `com.spiraldev.exchange_rate_calculator` |
| `--ios-bundle-id` | `com.spiraldev.{camelCase}` | `com.spiraldev.exchangeRateCalculator` |

---

## 5. 실행 단계 상세

### [1/6] release.yaml 편집

`release.yaml`의 `apps` 섹션에 새 앱 항목을 추가한다.

- YAML 파서(`yaml.safe_load`)로 파싱 후 항목 추가, `yaml.dump`로 재출력
- 파일 상단 주석은 별도 보존
- 이미 등록된 앱이면 경고 출력 후 스킵

추가되는 항목 구조:

```yaml
my_new_app:
  appId: com.spiraldev.my_new_app
  iosBundleId: com.spiraldev.myNewApp
  displayName: "My New App"
  projectPath: apps/my_new_app
  metadata:
    android: store_metadata/my_new_app/android.yaml
    ios: store_metadata/my_new_app/ios.yaml
  autoGenerateIcon: false
  autoCaptureScreenshots: false
  build:
    android:
      command: [flutter, build, appbundle, --release]
    ios:
      command: [flutter, build, ipa, --release]
  fastlane:
    androidLane: android_play_production
    iosLane: ios_appstore_release
```

### [2/6] GitHub Actions 워크플로우 편집

5개 워크플로우 파일에 앱을 추가한다. GitHub Actions YAML은 `${{ }}` 표현식을 포함하므로 YAML 파서가 아닌 **정규식 기반 텍스트 삽입**을 사용한다.

| 파일 | 수정 위치 | 비고 |
|------|-----------|------|
| `release-all.yaml` | test matrix.app | 항상 추가 |
| `release-all.yaml` | deploy-android matrix.app | `--exclude-from-release` 시 제외 |
| `release-all.yaml` | deploy-ios matrix.app | `--exclude-from-release` 시 제외 |
| `ci.yaml` | detect-changes filters | paths-filter 블록 추가 |
| `deploy-android.yaml` | workflow_dispatch options | choice 항목 추가 |
| `deploy-ios.yaml` | workflow_dispatch options | choice 항목 추가 |
| `deploy-all.yaml` | workflow_dispatch options | choice 항목 추가 |

`ci.yaml`에 추가되는 필터:

```yaml
my_new_app:
  - 'apps/my_new_app/**'
  - 'packages/**'
```

`--coverage-threshold`가 기본값(50)이 아닌 경우, 커버리지 체크 `case` 블록에 별도 임계값이 추가된다.

### [3/6] Android signing 설정

1. `signing/{app}/android/` 디렉토리 생성
2. `keytool`로 release keystore 생성 (RSA 2048, 유효기간 10,000일)
3. `key.properties` 파일 생성
4. GitHub Secrets 등록에 필요한 값 출력

생성되는 시크릿 목록:

| Secret 이름 | 값 |
|-------------|-----|
| `ANDROID_KEYSTORE_{APP_UPPER}_BASE64` | keystore의 base64 인코딩 |
| `ANDROID_STORE_PASSWORD_{APP_UPPER}` | 자동 생성된 store password |
| `ANDROID_KEY_PASSWORD_{APP_UPPER}` | 자동 생성된 key password |
| `ANDROID_KEY_ALIAS_{APP_UPPER}` | 앱 이름 (snake_case) |

비밀번호는 `secrets.token_urlsafe(16)`으로 자동 생성된다.

### [4/6] 메타데이터 템플릿 생성

Fastlane 메타데이터와 `store_metadata` 파일을 생성한다.

```
fastlane/metadata/{app}/
  en-US/
    name.txt, subtitle.txt, description.txt, keywords.txt,
    release_notes.txt, support_url.txt, privacy_url.txt
  ko/
    name.txt, subtitle.txt, description.txt, keywords.txt,
    release_notes.txt, support_url.txt, privacy_url.txt
  review_information/
    email_address.txt    → spiraldailydev@gmail.com
    first_name.txt       → Spiral
    last_name.txt        → Dev
    notes.txt
  copyright.txt          → 2026 Spiral Dev
  primary_category.txt   → LIFESTYLE
  rating_config.json     → 전 연령 등급

fastlane/screenshots/{app}/
  .gitkeep

store_metadata/{app}/
  android.yaml           → publisher.py 필수 필드 포함
  ios.yaml               → publisher.py 필수 필드 포함
```

`store_metadata`의 필수 필드 (`publisher.py`의 `validate_metadata()` 기준):
- `appName`, `shortDescription`, `fullDescription`
- `category`, `contact`, `privacyPolicyUrl`

### [5/6] build.gradle signing config 패치

`apps/{app}/android/app/build.gradle.kts` (또는 `.gradle`)에 signing config를 추가한다.

- **Kotlin DSL** (`.kts`): `import`, `keystoreProperties` 블록, `signingConfigs`, `buildTypes.release` 패치
- **Groovy DSL** (`.gradle`): 동일 구조의 Groovy 문법으로 패치
- **멱등성**: `keystoreProperties`가 이미 존재하면 스킵

패치 기준 템플릿: `apps/adage_spark/android/app/build.gradle.kts`

### [6/6] 스토어 등록

**App Store (Spaceship ConnectAPI):**
1. Spaceship ConnectAPI로 Apple Developer Portal에 Bundle ID 등록
2. App Store Connect에 앱 존재 여부 확인
3. `fastlane match appstore`로 프로비저닝 프로필 생성
4. App Store Connect API는 앱 생성(POST /v1/apps)을 지원하지 않으므로, 앱이 없으면 수동 생성 가이드를 출력한다

필요 환경변수:

| 환경변수 | 설명 |
|----------|------|
| `ASC_KEY_ID` | App Store Connect API Key ID |
| `ASC_ISSUER_ID` | App Store Connect Issuer ID |
| `ASC_KEY_FILEPATH` | .p8 파일 경로 (로컬용) |
| `ASC_KEY_CONTENT` | .p8 키 내용 (CI용, `ASC_KEY_FILEPATH` 대체) |
| `MATCH_PASSWORD` | match 암호화 비밀번호 (CI에서 자동 처리) |

**Google Play Store (수동):**
- Google Play Developer API는 신규 앱 생성을 지원하지 않음
- Play Console에서 수동 생성 가이드를 출력한다

---

## ASC API Key 크레덴셜

스토어 등록에 사용하는 App Store Connect API Key 정보:

| 항목 | 값 |
|------|-----|
| Key ID | `HZ89QN4W7U` |
| Issuer ID | `f42e9e12-3482-46c6-9e4d-d4e11d33de60` |
| 역할 | 관리자 (Admin) |
| .p8 파일 | `signing/asc/AuthKey_HZ89QN4W7U.p8` (gitignored) |
| Team ID | `BXMP99D98Z` |

로컬 환경변수 설정:

```bash
export ASC_KEY_ID="HZ89QN4W7U"
export ASC_ISSUER_ID="f42e9e12-3482-46c6-9e4d-d4e11d33de60"
export ASC_KEY_FILEPATH="signing/asc/AuthKey_HZ89QN4W7U.p8"
```

GitHub Secrets에는 `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_CONTENT` (base64)로 등록되어 있다.

### API 제약 사항

- Bundle ID 등록: 자동화 가능
- 앱 조회/수정: 자동화 가능
- match 프로비저닝: 자동화 가능 (`MATCH_PASSWORD` 필요)
- **앱 생성(POST /v1/apps): 불가** - Apple 플랫폼 제약으로 웹 콘솔에서만 가능

---

## 6. 생성/수정되는 파일 목록

### 수정되는 기존 파일

| 파일 | 변경 내용 |
|------|-----------|
| `release.yaml` | apps 섹션에 앱 항목 추가 |
| `.github/workflows/release-all.yaml` | test/deploy-android/deploy-ios matrix에 앱 추가 |
| `.github/workflows/ci.yaml` | detect-changes 필터 추가 |
| `.github/workflows/deploy-android.yaml` | workflow_dispatch options에 앱 추가 |
| `.github/workflows/deploy-ios.yaml` | workflow_dispatch options에 앱 추가 |
| `.github/workflows/deploy-all.yaml` | workflow_dispatch options에 앱 추가 |
| `apps/{app}/android/app/build.gradle.kts` | signing config 패치 |

### 새로 생성되는 파일

| 파일 | 내용 |
|------|------|
| `signing/{app}/android/release.keystore` | Android release keystore |
| `signing/{app}/android/key.properties` | keystore 접근 정보 |
| `fastlane/metadata/{app}/**` | App Store 메타데이터 템플릿 (20개 이상) |
| `fastlane/screenshots/{app}/.gitkeep` | 스크린샷 디렉토리 |
| `store_metadata/{app}/android.yaml` | Android 스토어 메타데이터 |
| `store_metadata/{app}/ios.yaml` | iOS 스토어 메타데이터 |

---

## 7. 에러 처리

- 각 단계는 독립적으로 실행된다. 한 단계 실패 시 경고 출력 후 다음 단계로 진행한다.
- 치명적 에러(앱 이름 유효성 실패, 앱 디렉토리 미존재)만 즉시 중단한다.
- `--dry-run` 모드에서 모든 변경을 미리 확인할 수 있다.

| 에러 상황 | 동작 |
|-----------|------|
| 유효하지 않은 앱 이름 (snake_case 아님) | exit 1 |
| `apps/{app}/` 디렉토리 미존재 | exit 1 |
| `apps/{app}/pubspec.yaml` 미존재 | exit 1 |
| release.yaml에 이미 등록된 앱 | 경고 출력, 스킵 |
| 워크플로우 파일에 이미 등록된 앱 | 경고 출력, 스킵 |
| build.gradle에 signing config 이미 존재 | 스킵 |
| keytool 미설치 | 경고 출력, signing 스킵 |
| bundler 미설치 | 경고 출력, 스토어 등록 스킵 |

---

## 8. 모듈 구조

```
tools/ci/
  register_app.py      # CLI 진입점, 오케스트레이션
  config_editor.py     # release.yaml 편집 (YAML 파서)
  workflow_editor.py   # GitHub Actions 워크플로우 편집 (정규식)
  signing_setup.py     # Android keystore 생성
  metadata_setup.py    # Fastlane/store 메타데이터 템플릿
  gradle_patcher.py    # build.gradle signing config 패치
  store_register.py    # App Store 등록 + Play Store 가이드
  name_utils.py        # snake_case <-> camelCase/PascalCase 변환
```

각 모듈은 독립적으로 import하여 사용할 수 있다.

```python
from tools.ci.name_utils import snake_to_camel, validate_app_name
from tools.ci.config_editor import add_app_to_release_config
```

---

## 9. 등록 후 체크리스트

도구 실행 후 아래 항목을 수동으로 완료해야 한다.

- [ ] `store_metadata/{app}/android.yaml` 필수 필드 채우기
- [ ] `store_metadata/{app}/ios.yaml` 필수 필드 채우기
- [ ] `fastlane/metadata/{app}/en-US/` 로케일 메타데이터 채우기
- [ ] `fastlane/metadata/{app}/ko/` 로케일 메타데이터 채우기
- [ ] GitHub repository Settings > Secrets에 시크릿 등록
- [ ] Google Play Console에서 앱 수동 생성 (Android)
- [ ] PR을 올려서 CI 파이프라인 동작 확인 (`detect-changes` 감지 여부)
- [ ] `flutter build apk --release` 로컬 빌드 성공 확인

---

## 10. 사용 예시

### 신규 앱 전체 등록

```bash
# 1. Flutter 프로젝트 생성
cd apps && flutter create --org com.spiraldev my_new_app && cd ..

# 2. CI/CD 등록 (dry-run으로 미리보기)
python3 tools/ci/register_app.py \
  --app my_new_app \
  --display-name "My New App" \
  --dry-run

# 3. 실제 등록
python3 tools/ci/register_app.py \
  --app my_new_app \
  --display-name "My New App"
```

### 프로토타입 앱 (배포 제외)

```bash
python3 tools/ci/register_app.py \
  --app my_prototype \
  --display-name "My Prototype" \
  --exclude-from-release \
  --skip-store \
  --skip-signing \
  --coverage-threshold 0
```

### 커스텀 ID로 등록

```bash
python3 tools/ci/register_app.py \
  --app my_app \
  --display-name "My App" \
  --app-id "com.mycompany.myapp" \
  --ios-bundle-id "com.mycompany.myApp"
```
