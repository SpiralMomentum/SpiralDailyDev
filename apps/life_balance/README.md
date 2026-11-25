# 인생잔고 (life_balance)

남은 삶을 통장 잔고처럼 보여주는 Android 위젯 앱. 서버/계정/네트워크 호출이 없고, 모든 사용자 데이터는 기기의 shared_preferences와 home_widget 저장소에만 남는다.

- applicationId: `com.spiralmomentum.life_balance`
- 대상 플랫폼: Android만 빌드/검증한다 (iOS 폴더는 `flutter create` 기본값)
- 설계: `docs/plans/2026-11-25-life-balance-design.md`, 구현 계획: `docs/plans/2026-11-25-life-balance.md`

## 실행

```bash
cd apps/life_balance
flutter pub get
flutter run                          # 연결된 Android 기기/에뮬레이터
flutter build appbundle --release    # build/app/outputs/bundle/release/app-release.aab
```

앱 시작 순서(`lib/app/bootstrap.dart`):

1. 폰트 라이선스 등록, SharedPreferences 열기, get_it에 저장소와 플랫폼 경계(위젯 게이트웨이, 알림, WorkManager 예약, 위젯 핀, URL 열기) 등록
2. `Workmanager().initialize(backgroundDispatcher)`
3. `assets/life_tables/life_tables.json`과 `assets/tones/*.json` 로드. 하나라도 실패하면 "데이터를 불러오지 못했습니다" 화면
4. 프로필이 있으면 위젯/상시 알림 동기화와 자정·1시간 갱신 작업 예약 후 통장 화면, 없으면 온보딩

릴리스 서명 설정은 아직 없다. 현재 release 빌드는 Flutter 기본 debug 키로 서명된다.

## 테스트

```bash
cd apps/life_balance
flutter analyze
flutter test                                          # Dart 단위/위젯 테스트
(cd android && ./gradlew :app:testDebugUnitTest)      # Kotlin 위젯 계산/알람 테스트
python3 -m unittest tool/test_build_life_tables.py    # 생명표 변환 스크립트 테스트
```

- `test/app/life_balance_app_test.dart`: 실제 앱 위젯으로 온보딩/통장 분기, 설정 변경 시 테마와 위젯 동기화, resumed 갱신, 에셋 로드 실패 화면
- `test/app/large_text_test.dart`: 시스템 글꼴 2.0배, 360x640dp 화면에서 통장/설정/온보딩 전 단계를 3말투 x 라이트/다크로 렌더해 overflow가 없음을 확인
- 플랫폼 호출은 `ServiceLocator.setup(...)`에 fake를 넘겨 대체한다 (`test/helpers/app_harness.dart`)

release 빌드에 `android.permission.INTERNET`이 없어야 한다. 확인 방법:

```bash
grep -o 'uses-permission[^>]*' build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml
```

## 데이터 갱신

### 생명표

`tool/build_life_tables.py`가 `tool/raw/`의 원본(IMF 순위, WHO GHO 생명표, 통계청 완전생명표 CSV)을 읽어 `assets/life_tables/life_tables.json`을 만든다. 출처 URL과 조회일, 원문 대조표는 `assets/life_tables/SOURCES.md`에 기록한다.

1. 원본을 갱신한다. IMF/WHO 응답은 curl로 받아 `tool/raw/`에 저장한다 (Python urllib 사용 금지). 한국 원본은 KOSIS 완전생명표(1세별) 남/여 기대여명 0~100세 CSV를 `tool/raw/kostat_life_table.csv`로 저장한다
2. 변환 테스트: `python3 -m unittest tool/test_build_life_tables.py`
3. 변환 실행: `python3 tool/build_life_tables.py`
4. `SOURCES.md`의 원문 값/JSON 값 대조표와 조회일을 갱신한다
5. `flutter test`로 생명표 에셋 테스트를 확인한다

### 말투 문구

`assets/tones/{stoic,wit,community}.json`을 수정한다. 모든 파일은 `PhraseKeys.all` 키를 빠짐없이 가져야 하고, 키마다 변형 1~5개, 이모지 금지다. `flutter test test/features/tone/`가 이를 검사한다.

### 카이로스 연결

`lib/main.dart`의 `AppConfig`에서 `kairosStatus`와 `kairosUrl`만 바꾼다.
