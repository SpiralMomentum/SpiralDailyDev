# self_eval_sim

선택지 기반 자기평가와 누적 발현을 제공하는 온디바이스 시뮬레이션 앱.

- 명세: `doc/self-eval-sim-app-spec.md` (PR #113)
- 명세에 없어 자체 판단한 항목: `doc/self-eval-sim-implementation-decisions.md`

## 구조

```
lib/
  app/                 조립 영역 (AppConfig, DI, 루트 위젯, bootstrap)
  features/
    model_pack/        최초 실행 온디바이스 모델(Gemma 4 E2B, 2.4GB) 내려받기 관문, 용량 상한
    simulation/        채널, 문항, 결과 장면, 누적 기록, 발현 규칙, 미연시형 결과 화면,
                       온디바이스 LLM 대사 생성(flutter_gemma) + 템플릿 대체
    monetization/      보상형 광고 제안 규칙, 연결 상태, 시뮬레이션 광고
    share/             결과 장면 GIF 인코딩과 공유
    settings/          언어 설정, 기록 요약/전체 삭제 화면
assets/
  content/             채널 구조(structure.json)와 언어별 문장(strings/{ko,en,ja,zh}.json)
  narration/           모델 프롬프트(prompts.json: 언어별 지시문, 줄 수, 길이, 금지 패턴)와 대체 템플릿(templates.json)
  images/scenes/       장면 배경 샘플 이미지 (SDXL 1.0 생성, 생성 조건은 doc 의 이미지 절)
```

## 실행

```bash
flutter run -d <arm64 기기>     # Hugging Face 에서 모델(2.4GB) 내려받기
# 로컬 미러 (에뮬레이터는 호스트를 10.0.2.2 로 본다. 평문 HTTP 는 디버그 빌드에서만 허용)
python3 -m http.server 8765 --bind 127.0.0.1 --directory <모델 파일 폴더>
flutter run --dart-define=MODEL_URL=http://10.0.2.2:8765/gemma-4-E2B-it.litertlm
```

Android arm64-v8a 전용 (x86_64 에뮬레이터 불가). 에뮬레이터는 RAM 8GB 이상 권장.

## 테스트

```bash
flutter test                  # 유닛 + 위젯(Bloc 포함)
MODEL_URL=http://10.0.2.2:8765/gemma-4-E2B-it.litertlm tool/record_integration.sh   # 플로우 테스트 + 녹화

# 실제 모델로 연속 시행 (개별/누적 발현 결과 수집) -> Markdown 리포트
SIM_REPORT=build/simulation/report_ko.json flutter drive --driver=test_driver/report_driver.dart \
  --target=integration_test/simulation_report_test.dart \
  --dart-define=MODEL_URL=... --dart-define=SIM_ATTEMPTS=40 --dart-define=SIM_LANGS=ko -d <device>
python3 tool/sim_report.py build/simulation/report_ko.json > report.md
```

`tool/record_integration.sh` 산출물 (`build/integration_video/`):

- `self_eval_flow_partNN.mp4`: 앱 프로세스 시작부터 테스트 종료까지 화면 녹화 (180초 단위 구간)
- `frames/*.png`: 3초 간격 스크린샷
- `drive.log`: flutter drive 로그

통합 테스트가 거치는 흐름: 최초 실행 모델 내려받기 -> 무협 1회차(개별 결과) -> GIF 공유 ->
무협 2회차(누적 발현, 보상형 광고 시청, 별도 발현 장면 + 확장 장면) -> 보석 3회차(발현 직후 0%) ->
오프라인 동물 4회차(발현은 있고 광고 없음, 섞인 발현) -> 설정(기록 4회/발현 2회, 영어 전환, 전체 삭제).

## 빌드

arm64-v8a 전용 APK (다른 ABI 와 쓰지 않는 네이티브 라이브러리는 `android/app/build.gradle.kts` 에서 제외). 릴리스 101.1MB.

```bash
flutter build apk --release
```
