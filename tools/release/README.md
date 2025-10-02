# Release Automation Toolkit

이 디렉터리는 `release.yaml`을 기반으로 각 앱의 스토어 배포를 자동화하기 위한 스크립트와 의존성을 제공합니다.

## 구성 요소

- `publisher.py`: 중앙 설정 파일을 읽어 아이콘 생성, 스크린샷 캡처, 빌드 및 Fastlane 실행 명령을 순차적으로 실행합니다.
- `icon_generator.py`: 색상과 레이블 정보를 받아 1024x1024 규격의 스토어 아이콘을 생성합니다.
- `requirements.txt`: 스크립트 실행에 필요한 Python 의존성(PyYAML, Pillow)을 정의합니다.

## 선행 조건

1. Python 3.10 이상
2. Fastlane, Flutter 및 관련 인증서/키가 로컬 또는 CI 환경에 설치 및 설정되어 있어야 합니다.
3. `release.yaml`에 각 앱의 경로와 스토어 메타데이터 파일이 올바르게 기재되어 있어야 합니다.

## 사용 방법

```bash
# 의존성 설치 (가상환경 권장)
pip install -r tools/release/requirements.txt

# 드라이런: 실제 명령을 실행하지 않고 예정된 작업을 출력합니다.
python tools/release/publisher.py

# 특정 앱만 실행
python tools/release/publisher.py --app daily_memo

# 실제 실행 (--execute 플래그로 드라이런 해제)
python tools/release/publisher.py --execute
```

### 주요 옵션

- `--skip-assets`: 아이콘 생성 및 스크린샷 캡처 과정을 건너뜁니다.
- `--skip-build`: 빌드 커맨드를 실행하지 않습니다.
- `--skip-fastlane`: Fastlane 레인을 실행하지 않습니다.
- `--app`: 실행할 앱을 지정합니다. 여러 번 지정 가능(`--app daily_memo --app spiral_trade_show`).

## 아이콘 자동 생성

`release.yaml`의 `autoGenerateIcon: true`와 아이콘 설정을 기반으로 `artifacts/<app>/app_icon.png` 파일이 생성됩니다. 템플릿 이미지를 덮어씌우고 싶다면 `icon.template` 경로를 지정할 수 있습니다.

## 스크린샷 자동 캡처

`autoCaptureScreenshots: true`로 설정된 앱은 시나리오별 명령을 실행하여 스크린샷을 캡처합니다. 일반적으로 `flutter drive`나 `fastlane snapshot`과 같은 명령을 입력합니다. 출력 디렉터리는 `screenshots.outputPath`에 정의됩니다.

## Fastlane 통합

각 플랫폼별 Fastlane 레인은 `fastlane.androidLane`, `fastlane.iosLane`에 정의합니다. `publisher.py`는 다음 파라미터를 레인에 전달합니다.

- `metadata_path`: YAML 메타데이터 파일 경로 (절대 경로)
- `artifact_path`: 빌드 결과/스크린샷을 찾을 기본 디렉터리
- `icon_path`: 자동 생성된 아이콘 경로 (존재할 경우)
- `skip_screenshots`: 스크린샷 업로드 건너뛰기 여부

레인 내부에서 위 파라미터를 읽어 `fastlane supply` 또는 `deliver`를 호출하도록 구성하면 전체 배포 흐름을 자동화할 수 있습니다.
