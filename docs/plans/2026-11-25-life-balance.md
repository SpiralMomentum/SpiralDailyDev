# 인생잔고 (life_balance) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 생명표 기대여명으로 남은 삶을 은행 잔고처럼 보여주는 Android 앱(위젯, 상시 알림, 말투 3종, 테마)을 `apps/life_balance`에 만든다.

**Architecture:** Flutter 앱은 기존 앱 구조(`lib/app` + `lib/features/<feature>/{data,domain,presentation}`, flutter_bloc, get_it)를 따른다. 잔고 계산은 Flutter 의존 없는 순수 Dart 함수로 두고, 앱/백그라운드 작업(WorkManager)이 같은 함수를 쓴다. 홈 화면 위젯은 Kotlin Glance로 작성하고, 앱이 기록한 "만기일 일정 + 문구 변형 + 색상"만 읽어 매 렌더마다 직접 계산한다. Dart와 Kotlin의 계산 일치는 공용 테스트 벡터 JSON으로 검증한다.

**Tech Stack:** Flutter 3.41.2 / Dart 3.11.0, flutter_bloc, get_it, equatable, shared_preferences, home_widget, flutter_local_notifications, workmanager, url_launcher, intl, mocktail, bloc_test; Android Kotlin + Jetpack Glance; Python 3 (데이터 변환 스크립트, 표준 라이브러리만).

**Spec:** `docs/plans/2026-11-25-life-balance-design.md` (원본 기획서 `doc/26_Q4/인생잔고_기획서.md`)

## Global Constraints

- 앱 경로 `apps/life_balance`, applicationId/namespace `com.spiralmomentum.life_balance`, 앱 표시 이름 `인생잔고`
- Android만 빌드/검증한다. iOS 폴더는 `flutter create` 기본값 그대로 두고 손대지 않는다
- 네트워크 권한(`INTERNET`)을 release manifest에 추가하지 않는다. 서버/계정/네트워크 호출 금지
- 모든 사용자 데이터는 shared_preferences / home_widget 저장소에만 둔다
- 테스트 모킹은 mocktail. build_runner/코드 생성 금지 (freezed, json_serializable 사용 안 함)
- 함수는 순수 함수와 불변 값 우선. 부수효과(저장, 플랫폼 호출)는 data 계층과 `lib/app`에만 둔다
- domain 계층은 `package:flutter` import 금지 (백그라운드 isolate에서 재사용)
- 날짜는 시각 없이 로컬 달력 날짜(`CalendarDate`)로만 계산. 1년 = 365.2425일
- UI 언어는 한국어 단일. 이모지 사용 금지
- 잔고 숫자는 앱에서 `FontFeature.tabularFigures()`, 위젯에서 시스템 산세리프
- 리서치 사실(생명표 수치, IMF 순위, 폰트 라이선스)은 원문 URL과 조회일을 `SOURCES.md`에 기록하고, 원문과 대조한 근거 없이 확정하지 않는다
- 커밋 메시지 형식: `feat(life_balance): ...` 등 기존 conventional 형식, 끝에 `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

## Review Focus

1. 앱을 생일 전날 이후 열지 않은 상태로 생일을 넘김 → 위젯이 일정의 다음 항목으로 넘어가 새 만기일 기준으로 표시 (Task 3, Task 10 벡터 `birthday_rollover`)
2. 2월 29일생이 평년을 지남 → 2월 28일에 나이가 오르고 기준일도 2월 28일 (Task 2 `feb29 birthday in common year`)
3. 수동 기대수명이 현재 나이보다 작음(이미 만기 지남) → 보너스 잔고로 표시되고 진행 막대 100%, 음수 표시 없음 (Task 2, Task 3 `bonus` 벡터)
4. 기기 시간대/날짜 수동 변경 → 위젯이 즉시 새 날짜 기준으로 재계산 (Task 10 `DateChangeReceiver` 수동 검증, Task 11 재예약 테스트)
5. 사용자가 Android 14+에서 상시 알림을 밀어 지움 / 알림 권한 거부 → 앱 재실행·다음 갱신 때 다시 표시, 권한 거부 시 설정 토글이 꺼짐으로 보이고 크래시 없음 (Task 11)

---

## File Structure

```
apps/life_balance/
  pubspec.yaml, analysis_options.yaml
  assets/life_tables/life_tables.json, SOURCES.md
  assets/tones/stoic.json, wit.json, community.json
  assets/fonts/  (Pretendard, 명조, 둥근 고딕 + OFL 라이선스 파일)
  test_vectors/balance_vectors.json        # Dart, Kotlin 공용
  tool/build_life_tables.py, tool/test_build_life_tables.py, tool/raw/ (원본 CSV)
  lib/main.dart
  lib/app/{app_config.dart, bootstrap.dart, life_balance_app.dart, di/service_locator.dart, background/background_dispatcher.dart}
  lib/features/balance/domain/{calendar_date.dart, profile.dart, balance.dart, balance_calculator.dart, balance_format.dart, maturity_schedule.dart}
  lib/features/balance/presentation/{passbook_page.dart, passbook_cubit.dart, widgets/...}
  lib/features/life_table/domain/life_table.dart
  lib/features/life_table/data/{life_table_parser.dart, asset_life_table_repository.dart}
  lib/features/profile/domain/{settings.dart, profile_repository.dart}
  lib/features/profile/data/prefs_profile_repository.dart
  lib/features/profile/presentation/onboarding/{onboarding_page.dart, onboarding_cubit.dart}
  lib/features/tone/domain/{tone.dart, tone_table.dart, phrase_keys.dart}
  lib/features/tone/data/asset_tone_repository.dart
  lib/features/tone/presentation/tone_theme.dart
  lib/features/widget_sync/domain/widget_payload.dart
  lib/features/widget_sync/data/home_widget_sync.dart
  lib/features/ongoing_notification/domain/midnight.dart
  lib/features/ongoing_notification/data/{ongoing_notifier.dart, midnight_scheduler.dart}
  lib/features/settings/presentation/{settings_page.dart, settings_cubit.dart}
  lib/features/kairos/presentation/kairos_card.dart
  android/app/src/main/kotlin/com/spiralmomentum/life_balance/widget/{BalanceCalc.kt, WidgetData.kt, SmallBalanceWidget.kt, MediumBalanceWidget.kt, receivers}
  android/app/src/test/kotlin/com/spiralmomentum/life_balance/widget/BalanceCalcTest.kt
```

---

### Task 1: 앱 스캐폴드

**Files:**
- Create: `apps/life_balance/` (`flutter create --org com.spiralmomentum --project-name life_balance --platforms android,ios apps/life_balance`)
- Modify: `apps/life_balance/pubspec.yaml`, `apps/life_balance/android/app/build.gradle.kts`, `apps/life_balance/android/app/src/main/AndroidManifest.xml`
- Test: `apps/life_balance/test/smoke_test.dart`

**Interfaces:**
- Produces: 빌드 가능한 빈 앱, `lib/main.dart`가 `bootstrap()` 호출 (Task 15에서 채움; 이 Task에서는 `MaterialApp(home: SizedBox())`)

- [ ] **Step 1:** `flutter create` 실행 후 기본 counter 코드와 `test/widget_test.dart` 삭제
- [ ] **Step 2:** pubspec: `description: "남은 삶을 잔고처럼 보여주는 위젯 앱"`, `version: 0.1.0+1`, `sdk: ^3.11.0`. `flutter pub add flutter_bloc get_it equatable shared_preferences home_widget flutter_local_notifications workmanager url_launcher intl` 및 dev `bloc_test mocktail`. utils 패키지 `path: ../../packages/utils`. 각 패키지가 해결된 버전을 pubspec에 고정(`^x.y.z`)
- [ ] **Step 3:** Android: `minSdk = 26` (Glance, requestPinAppWidget), `android:label="인생잔고"`, 권한 `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`. flutter_local_notifications 요구사항대로 `isCoreLibraryDesugaringEnabled = true` + desugar 의존성 추가
- [ ] **Step 4:** smoke test: `testWidgets('app builds', ...)`가 `MaterialApp` 렌더 확인
- [ ] **Step 5:** Run `cd apps/life_balance && flutter analyze && flutter test && flutter build apk --debug` → 모두 성공
- [ ] **Step 6:** Commit `feat(life_balance): 앱 스캐폴드`

### Task 2: 잔고 계산 domain

**Files:**
- Create: `lib/features/balance/domain/calendar_date.dart`, `profile.dart`, `balance.dart`, `balance_calculator.dart`, `lib/features/life_table/domain/life_table.dart`
- Test: `test/features/balance/domain/balance_calculator_test.dart`

**Interfaces:**
- Produces:
  - `class CalendarDate extends Equatable { const CalendarDate(int year, int month, int day); factory CalendarDate.fromDateTime(DateTime dt); factory CalendarDate.parse(String yyyyMmDd); int get epochDay; CalendarDate addDays(int days); int daysUntil(CalendarDate other); /* other - this */ String toIso(); bool isBefore(CalendarDate o); }` — epochDay는 `DateTime.utc(y,m,d)` 기반
  - `enum Sex { male, female }`
  - `class Profile extends Equatable { final CalendarDate birthDate; final Sex sex; final String countryCode; /* ISO alpha-2 */ final double? manualLifespanYears; Profile copyWith(...); }`
  - `abstract interface class LifeTable { double remainingYears({required String countryCode, required Sex sex, required int age}); List<String> get countryCodes; }` — 100세 초과는 100세 값
  - `class Balance extends Equatable { final int remainingDays; /* 보너스면 0 */ final int bonusDays; /* 보너스 아니면 0 */ final int totalDays; /* maturity - birth */ bool get isBonus => bonusDays > 0 || remainingDays == 0; }`
  - `int ageOn(CalendarDate birth, CalendarDate today)`
  - `CalendarDate birthdayOf(CalendarDate birth, int year)` — 2/29생은 평년 2/28
  - `CalendarDate maturityDate({required Profile profile, required CalendarDate today, required LifeTable table})`
  - `double estimatedLifespanYears({required Profile profile, required CalendarDate today, required LifeTable table})` — `age + e(age)`, 소수 1자리 반올림
  - `Balance computeBalance({required CalendarDate birth, required CalendarDate maturity, required CalendarDate today})`

규칙(설계 5.3): 생명표 모드 `maturity = birthdayOf(birth, birth.year + age).addDays((e(age) * 365.2425).round())`. 수동 모드 `maturity = birth + manualLifespanYears`: 정수 년은 `birthdayOf(birth, birth.year + whole)`, 소수부는 `(frac * 365.2425).round()`일 추가.

- [ ] **Step 1: 실패 테스트 작성** (테스트용 `FakeLifeTable`은 age→값 Map)
  - `ageOn`: birth 1990-05-10, today 2026-05-09 → 35; 2026-05-10 → 36
  - `feb29 birthday in common year`: birth 2000-02-29, today 2027-02-28 → age 27, `birthdayOf(birth, 2027)` == 2027-02-28; today 2027-02-27 → 26
  - `maturityDate table mode`: birth 1990-05-10, today 2026-11-25, e(36)=45.0 → 2026-05-10 + 16436일 (45×365.2425=16435.9 → 16436)
  - `maturity anchored to birthday not today`: 같은 프로필에서 today 2026-11-25와 2027-03-01의 maturity 동일
  - `manual mode`: birth 1990-05-10, manual 80.5 → 2070-05-10 + 183일
  - `computeBalance`: maturity−today=100 → remainingDays 100, bonusDays 0; maturity == today → remaining 0, isBonus true; today = maturity+5 → remaining 0, bonus 5
  - `age over 100 uses 100`: FakeLifeTable가 age 100까지만 있고 age 103 조회 시 예외 없이 계산
- [ ] **Step 2:** Run `flutter test test/features/balance/domain/balance_calculator_test.dart` → FAIL (정의 없음)
- [ ] **Step 3:** 위 시그니처 구현
- [ ] **Step 4:** 같은 명령 → PASS
- [ ] **Step 5:** Commit `feat(life_balance): 잔고 계산 domain`

### Task 3: 단위 표시, 만기일 일정, 공용 테스트 벡터

**Files:**
- Create: `lib/features/balance/domain/balance_format.dart`, `maturity_schedule.dart`, `test_vectors/balance_vectors.json`
- Test: `test/features/balance/domain/balance_format_test.dart`, `test/features/balance/domain/vectors_test.dart`

**Interfaces:**
- Consumes: Task 2 전부
- Produces:
  - `enum BalanceUnit { days, weeks, years, percent }`
  - `String formatBalanceValue(Balance b, BalanceUnit unit)` — 숫자+단위: 일 `12,345일`, 주 `1,763주`(floor(d/7)), 년 `33.8년`(d/365.2425 소수1자리 내림), 백분율 `41.2%`(remaining/total×100 소수1자리 내림). 보너스면 bonusDays 기준으로 같은 단위 + 앞에 `+` (백분율 단위에서 보너스는 `+N일`로 일 단위 표시)
  - `double usedRatio(Balance b)` — `1 - remaining/total`, [0,1] clamp, 보너스면 1.0
  - `class ScheduleEntry extends Equatable { final CalendarDate validFrom; final CalendarDate maturity; Map<String,String> toJson(); }`
  - `List<ScheduleEntry> buildSchedule({required Profile profile, required CalendarDate today, required LifeTable table, int years = 10})` — 첫 항목 validFrom = 최근 생일(수동 모드면 birthDate, 항목 1개), 이후 매 생일마다 항목
  - `ScheduleEntry entryFor(List<ScheduleEntry> schedule, CalendarDate today)` — validFrom ≤ today 인 마지막 항목, 없으면 첫 항목
- 벡터 JSON 형식: `[{ "name": str, "birth": "YYYY-MM-DD", "today": "...", "schedule": [{"validFrom","maturity"}], "unit": "days|weeks|years|percent", "expected": {"remainingDays": int, "bonusDays": int, "display": str, "usedRatioPermille": int /* round(ratio*1000) */ } }]`

- [ ] **Step 1: 실패 테스트 작성**
  - format: remaining 12345 → `12,345일`; 주 `1,763주`; total 30000 remaining 12345 → `41.1%`(41.15 내림); years 12345 → `33.7년`(33.799 내림); bonus 400 days → `+400일`, weeks → `+57주`
  - `usedRatio`: total 30000 remaining 12345 → 0.5885; bonus → 1.0
  - schedule: 생명표 모드 years=10 → 항목 10개, validFrom이 매년 생일, maturity가 각 나이 e로 계산
  - `entryFor`: 생일 당일엔 새 항목, 전날엔 이전 항목
  - 벡터 최소 6개 작성: `days_basic`, `weeks_basic`, `years_basic`, `percent_basic`, `birthday_rollover`(today가 두 번째 항목 validFrom 당일), `bonus`(today > maturity). `vectors_test.dart`가 파일을 읽어 각 벡터에서 `entryFor`→`computeBalance`→`formatBalanceValue`/`usedRatio` 결과가 expected와 같은지 검사
- [ ] **Step 2:** Run `flutter test test/features/balance/domain/` → FAIL
- [ ] **Step 3:** 구현. 벡터의 expected 값은 손으로 계산해 넣는다(구현 출력 복사 금지)
- [ ] **Step 4:** Run 같은 명령 → PASS
- [ ] **Step 5:** Commit `feat(life_balance): 단위 표시와 만기일 일정`

### Task 4: 생명표 데이터 수집과 변환

**Files:**
- Create: `tool/build_life_tables.py`, `tool/test_build_life_tables.py`, `tool/raw/*`, `assets/life_tables/life_tables.json`, `assets/life_tables/SOURCES.md`

**Interfaces:**
- Produces: `life_tables.json` 스키마 `{ "version": "2026.11", "countries": { "<ISO2>": { "name": "<한국어 국가명>", "source": {"name": str, "url": str, "year": int, "retrieved": "YYYY-MM-DD"}, "male": [101개 float], "female": [101개 float] } } }` — 인덱스 = 나이 0~100, 값은 기대여명(년) 소수 2자리

- [ ] **Step 1: 국가 목록 확정.** IMF WEO 명목 GDP(USD, 최신 연도) 상위 10개국을 IMF DataMapper(`https://www.imf.org/external/datamapper/api/v1/NGDPD`)에서 curl로 받아 정렬(Python urllib 금지, curl 사용). 집계 지역 코드 제외. 결과 10개국 + KR. 응답 원본을 `tool/raw/imf_ngdpd.json`에 저장하고 순위표를 SOURCES.md에 기록
- [ ] **Step 2: WHO 원본 수집.** WHO GHO OData의 생명표 기대여명 지표(ex, abridged life table; 지표 코드는 `https://ghoapi.azureedge.net/api/Indicator`에서 "Life expectancy at age x" 검색으로 확정)를 10개국 × 남녀로 curl 수집, 최신 연도 선택(설계 결정: WHO 최신 연도). `tool/raw/who_<ISO3>.json` 저장
- [ ] **Step 3: 한국 원본 수집.** KOSIS 완전생명표(1세별) 최신 연도 남/여 기대여명 0~100세를 CSV로 확보해 `tool/raw/kostat_life_table.csv` 저장. KOSIS OpenAPI 키가 필요하거나 자동 다운로드가 막히면 작업을 멈추고 사용자에게 CSV 다운로드를 요청한다
- [ ] **Step 4: 변환 함수 테스트 작성** (`unittest`)
  - `interpolate_abridged({0: 80.0, 1: 79.5, 5: 75.6, 10: 70.6}, max_age=10)` → 인덱스 1..5 선형(2세 = 79.5 − (79.5−75.6)/4 = 78.525)
  - `extend_over_85(country_e85=7.0, korea_tail=[8.0, 7.5, ..., 2.0])` → 86세 값 = korea[86]×7.0/8.0
  - `validate(series)`: 길이가 101이 아니거나, 음수/0 이하 값이 있거나, 1세 이후 값이 다음 나이보다 작으면(증가) `ValueError`. 0세 < 1세는 허용(영아 사망 영향)
- [ ] **Step 5:** Run `python3 -m unittest apps/life_balance/tool/test_build_life_tables.py` → FAIL
- [ ] **Step 6:** `build_life_tables.py` 구현(순수 함수 + 마지막 main에서 파일 IO). 86~100세 규칙: `e_c(x) = e_KR(x) × e_c(85) / e_KR(85)` 같은 성별
- [ ] **Step 7:** Run 테스트 → PASS. 스크립트 실행해 JSON 생성
- [ ] **Step 8: 원문 대조.** 국가별 1개 이상 값(예: KR 남 0세, USA 여 60세 구간 시작 나이 값)을 원문 응답과 비교해 SOURCES.md에 "원문 값 / JSON 값" 표로 기록. 불일치 시 수정
- [ ] **Step 9:** Commit `feat(life_balance): 11개국 생명표 데이터와 변환 스크립트`

### Task 5: 생명표 로딩

**Files:**
- Create: `lib/features/life_table/data/life_table_parser.dart`, `asset_life_table_repository.dart`
- Modify: `pubspec.yaml` (assets: `assets/life_tables/`)
- Test: `test/features/life_table/life_table_parser_test.dart`, `test/features/life_table/life_table_asset_test.dart`

**Interfaces:**
- Consumes: `LifeTable`, `Sex` (Task 2)
- Produces:
  - `class CountryInfo extends Equatable { final String code; final String name; final String sourceName; final int sourceYear; }`
  - `class JsonLifeTable implements LifeTable { List<CountryInfo> get countries; }`
  - `Result<JsonLifeTable> parseLifeTable(String json)` — 형식 오류는 `ParsingFailure`
  - `class AssetLifeTableRepository { Future<Result<JsonLifeTable>> load(); }` (`rootBundle`)

- [ ] **Step 1:** 실패 테스트: 2개국 미니 JSON → `remainingYears(KR, male, 0)` 값 일치, 101 초과 나이는 100 값, 알 수 없는 국가는 `ArgumentError`, 배열 길이 100이면 `ErrorResult`. 에셋 테스트: 실제 에셋 로드 시 국가 11개, 모든 국가 남녀 101개, KR 포함
- [ ] **Step 2:** Run `flutter test test/features/life_table/` → FAIL
- [ ] **Step 3:** 구현
- [ ] **Step 4:** Run → PASS
- [ ] **Step 5:** Commit `feat(life_balance): 생명표 로딩`

### Task 6: 프로필과 설정 저장소

**Files:**
- Create: `lib/features/profile/domain/settings.dart`, `profile_repository.dart`, `lib/features/profile/data/prefs_profile_repository.dart`, `lib/features/tone/domain/tone.dart`
- Test: `test/features/profile/prefs_profile_repository_test.dart`

**Interfaces:**
- Consumes: `Profile`, `BalanceUnit`
- Produces:
  - `enum ToneId { stoic, wit, community }` (`tone.dart`)
  - `enum ThemePref { system, light, dark }`
  - `class AppSettings extends Equatable { final BalanceUnit unit; /* 기본 days */ final ToneId tone; /* 기본 stoic */ final ThemePref themePref; /* 기본 system */ final bool ongoingNotification; /* 기본 true */ static const defaults; AppSettings copyWith(...); }`
  - `abstract interface class ProfileRepository { Future<Profile?> loadProfile(); Future<void> saveProfile(Profile p); Future<AppSettings> loadSettings(); Future<void> saveSettings(AppSettings s); }`
  - `class PrefsProfileRepository implements ProfileRepository { PrefsProfileRepository(SharedPreferences prefs); }` — 키 접두사 `lb.`
- [ ] **Step 1:** 실패 테스트(`SharedPreferences.setMockInitialValues({})`): 저장 전 `loadProfile()` null, 저장 후 동일 값(수동값 null/80.5 둘 다), 설정 기본값, 알 수 없는 enum 문자열 저장돼 있으면 기본값
- [ ] **Step 2:** Run `flutter test test/features/profile/` → FAIL
- [ ] **Step 3:** 구현
- [ ] **Step 4:** Run → PASS
- [ ] **Step 5:** Commit `feat(life_balance): 프로필과 설정 저장소`

### Task 7: 말투 문구 테이블

**Files:**
- Create: `lib/features/tone/domain/tone_table.dart`, `phrase_keys.dart`, `lib/features/tone/data/asset_tone_repository.dart`, `assets/tones/stoic.json`, `wit.json`, `community.json`, `test/features/tone/banned_words.txt`
- Test: `test/features/tone/tone_table_test.dart`, `test/features/tone/tone_assets_test.dart`, `test/features/tone/community_policy_test.dart`

**Interfaces:**
- Consumes: `ToneId`, `CalendarDate`
- Produces:
  - `abstract final class PhraseKeys` 상수: `mainTitle='main.title'`, `mainBalanceLabel='main.balance_label'`, `mainOpenedLabel='main.opened_label'`, `mainMaturityLabel='main.maturity_label'`, `mainWithdrawal='main.withdrawal'`, `mainBonusNotice='main.bonus_notice'`, `widgetSmallLabel='widget.small_label'`, `widgetMediumLabel='widget.medium_label'`, `widgetWithdrawal='widget.withdrawal'`, `widgetBonusLabel='widget.bonus_label'`, `notificationBody='notification.body'`, `notificationBonusBody='notification.bonus_body'`, `onboardingIntro='onboarding.intro'`, `onboardingWidgetGuide='onboarding.widget_guide'`, `kairosIntro='kairos.intro'`, `kairosCta='kairos.cta'`; `static const all = [...]`
  - `class ToneTable extends Equatable { final ToneId id; final Map<String, List<String>> phrases; }`
  - `Result<ToneTable> parseToneTable(ToneId id, String json)` — 형식 `{ "<key>": ["문장", ...] }`
  - `String pickPhrase(ToneTable t, String key, CalendarDate today)` — `variants[today.epochDay % variants.length]`
  - `String fillPlaceholders(String template, Map<String, String> vars)` — `{balance}`, `{bonus}` 치환, 없는 변수는 그대로 둠
  - `class AssetToneRepository { Future<Result<ToneTable>> load(ToneId id); }`
- 문구 원칙: 스토아=진지/철학, 위트=가볍고 장난스러움, 커뮤니티=디시식 어휘/어미(혐오·차별·성적 표현·집단 비하 금지). `notification.body` 기본형은 `인생잔고 {balance} · 오늘 -1일`의 말투 변형. 키마다 변형 1~5개

- [ ] **Step 1:** 실패 테스트: `pickPhrase` 같은 날 같은 결과/다음 날 다음 변형, `fillPlaceholders('인생잔고 {balance} · 오늘 -1일', {'balance':'12,345일'})` == `인생잔고 12,345일 · 오늘 -1일`. 에셋 테스트: 3개 파일 모두 `PhraseKeys.all` 키 전부 보유, 빈 배열/빈 문자열 없음, 이모지 없음(유니코드 `\p{Extended_Pictographic}` 정규식), `notification.body`는 `{balance}` 포함. 정책 테스트: `banned_words.txt`(한 줄 1단어, 혐오·차별·비하 표현 목록 — 성별·지역·장애·인종·성소수자 비하 은어 포함) 단어가 community.json에 없음
- [ ] **Step 2:** Run `flutter test test/features/tone/` → FAIL
- [ ] **Step 3:** 구현 + 문구 3종 작성
- [ ] **Step 4:** Run → PASS
- [ ] **Step 5:** Commit `feat(life_balance): 말투 3종 문구 테이블`

### Task 8: 말투별 테마와 폰트

**Files:**
- Create: `lib/features/tone/presentation/tone_theme.dart`, `assets/fonts/*` (+ 각 폰트 `OFL.txt`), `assets/fonts/SOURCES.md`
- Modify: `pubspec.yaml` (fonts)
- Test: `test/features/tone/tone_theme_test.dart`

**Interfaces:**
- Consumes: `ToneId`
- Produces:
  - `class TonePalette { final Color background, foreground, accent, surface; }`
  - `TonePalette paletteFor(ToneId tone, Brightness b)`
  - `ThemeData themeFor(ToneId tone, Brightness b)` — 본문 `fontFamily: 'Pretendard'`, `textTheme.displayLarge`(잔고 숫자)와 제목은 말투 폰트(`StoicSerif`/`WitRounded`/`Pretendard`), displayLarge에 `fontFeatures: [FontFeature.tabularFigures()]`
  - 폰트 family 이름: `Pretendard`, `StoicSerif`(나눔명조 후보), `WitRounded`(둥근 고딕 OFL 후보)
- 색 기준: 스토아 라이트 bg `#F6F1E7` fg `#2B2B2B` accent `#B08D57`; 위트 bg `#FFF4F0` fg `#3A3A3A` accent `#FF7F6E`; 커뮤니티 bg `#FFFFFF` surface `#F2F3F5` fg `#111111` accent `#3B5BDB`. 다크는 bg/fg 반전 계열(구현자 판단), accent 유지. 대비 4.5:1 이상

- [ ] **Step 1:** 폰트 다운로드(curl), 각 라이선스 원문 확인 후 OFL 등 앱 번들 재배포 허용 근거를 `assets/fonts/SOURCES.md`에 URL과 함께 기록. 허용이 확인되지 않은 폰트는 쓰지 않는다
- [ ] **Step 2:** 실패 테스트: 3말투 × 2밝기에서 fg/bg 대비 ≥ 4.5 (WCAG 상대휘도 계산 헬퍼), displayLarge에 tabularFigures 포함, 본문 fontFamily == 'Pretendard'
- [ ] **Step 3:** Run `flutter test test/features/tone/tone_theme_test.dart` → FAIL
- [ ] **Step 4:** 구현
- [ ] **Step 5:** Run → PASS
- [ ] **Step 6:** Commit `feat(life_balance): 말투별 테마와 폰트`

### Task 9: 위젯 데이터 동기화

**Files:**
- Create: `lib/features/widget_sync/domain/widget_payload.dart`, `lib/features/widget_sync/data/home_widget_sync.dart`
- Test: `test/features/widget_sync/widget_payload_test.dart`, `test/features/widget_sync/home_widget_sync_test.dart`

**Interfaces:**
- Consumes: `Profile`, `AppSettings`, `LifeTable`, `ToneTable`, `buildSchedule`, `paletteFor`, `PhraseKeys`
- Produces:
  - `class WidgetPayload extends Equatable { Map<String, String> toEntries(); }` — 키(Kotlin과 공유, 정확히 이 이름): `lb_schedule`(ScheduleEntry 배열 JSON), `lb_birth`(ISO), `lb_unit`(enum name), `lb_tone`, `lb_colors_light`/`lb_colors_dark`(`{"bg":int,"fg":int,"accent":int}` ARGB), `lb_phrases`(`{"widget.small_label":[...],"widget.medium_label":[...],"widget.withdrawal":[...],"widget.bonus_label":[...]}`)
  - `WidgetPayload buildWidgetPayload({required Profile profile, required AppSettings settings, required LifeTable table, required ToneTable tone, required CalendarDate today})`
  - `abstract interface class WidgetGateway { Future<void> save(Map<String,String> entries); Future<void> refresh(); }` + `HomeWidgetGateway` 구현(`HomeWidget.saveWidgetData`, `HomeWidget.updateWidget(qualifiedAndroidName: 'com.spiralmomentum.life_balance.widget.SmallBalanceReceiver')`와 Medium 둘 다)
  - `Future<void> syncWidget({required WidgetPayload payload, required WidgetGateway widgets})` — save 후 refresh. Task 11의 `syncDerivedOutputs`가 이를 호출한다
- [ ] **Step 1:** 실패 테스트: payload 엔트리 키 집합 정확히 일치, `lb_schedule` 항목 10개, `lb_phrases`에 위젯 키 4개만. `syncWidget` 테스트: mocktail `WidgetGateway`에 save → refresh 순서로 호출
- [ ] **Step 2:** Run `flutter test test/features/widget_sync/` → FAIL
- [ ] **Step 3:** 구현
- [ ] **Step 4:** Run → PASS
- [ ] **Step 5:** Commit `feat(life_balance): 위젯 데이터 동기화`

### Task 10: Android Glance 위젯 (소형/중형)

**Files:**
- Create: `android/app/src/main/kotlin/com/spiralmomentum/life_balance/widget/BalanceCalc.kt`, `WidgetData.kt`, `SmallBalanceWidget.kt`(+`SmallBalanceReceiver`), `MediumBalanceWidget.kt`(+`MediumBalanceReceiver`), `DateChangeReceiver.kt`, `res/xml/small_balance_info.xml`, `res/xml/medium_balance_info.xml`, `res/layout/widget_loading.xml`
- Modify: `android/app/build.gradle.kts` (Glance, home_widget glance 의존, `testImplementation("junit:junit:4.13.2")`, `testImplementation("org.json:json:20240303")`), `AndroidManifest.xml`
- Test: `android/app/src/test/kotlin/com/spiralmomentum/life_balance/widget/BalanceCalcTest.kt`

**Interfaces:**
- Consumes: Task 9 키 이름, Task 3 벡터 파일과 규칙
- Produces (Kotlin):
  - `data class Entry(val validFrom: LocalDate, val maturity: LocalDate)`
  - `object BalanceCalc { fun entryFor(schedule: List<Entry>, today: LocalDate): Entry; fun compute(birth: LocalDate, maturity: LocalDate, today: LocalDate): Balance; fun format(b: Balance, unit: String): String; fun usedRatio(b: Balance): Double; fun pick(variants: List<String>, today: LocalDate): String }` — Dart와 같은 규칙(epochDay = `LocalDate.toEpochDay()`, 천 단위 구분 `,`)
  - `data class WidgetData(...)` + `fun readWidgetData(prefs: SharedPreferences): WidgetData?` (home_widget 저장소, 값 없으면 null → "앱에서 설정을 완료하세요" 표시)

- [ ] **Step 1:** 실패 테스트: `BalanceCalcTest`가 `File("../../test_vectors/balance_vectors.json")`(gradle unit test 작업 디렉터리 = `android/app`)을 읽어 모든 벡터에서 remainingDays, bonusDays, display, `round(usedRatio*1000)` 일치. `pick` 테스트: epochDay 20000, 변형 3개 → 인덱스 20000 % 3
- [ ] **Step 2:** Run `cd apps/life_balance/android && ./gradlew :app:testDebugUnitTest` → FAIL
- [ ] **Step 3:** `BalanceCalc` 구현 → 같은 명령 PASS
- [ ] **Step 4:** Glance 위젯 구현. 소형: 큰 숫자(`FontFamily.SansSerif`) + 라벨(스토아면 `FontFamily.Serif`). 중형: 숫자, `widget.withdrawal` 문구, `LinearProgressIndicator(usedRatio)`. 보너스면 `widget.bonus_label`. 색은 시스템 다크 여부로 light/dark 선택. 탭 → `MainActivity`. 매 `provideGlance`에서 `LocalDate.now()` 기준 재계산
- [ ] **Step 5:** `DateChangeReceiver`: `ACTION_DATE_CHANGED`, `ACTION_TIME_CHANGED`, `ACTION_TIMEZONE_CHANGED`, `BOOT_COMPLETED` 수신 → 두 위젯 `updateAll`. manifest 등록, 위젯 info: 소형 minWidth 110dp/minHeight 40dp, 중형 250dp/110dp, `updatePeriodMillis=1800000`
- [ ] **Step 6:** Run `cd apps/life_balance && flutter build apk --debug` → 성공
- [ ] **Step 7: 에뮬레이터 수동 검증** (API 34): 위젯 2종 추가 → 표시 확인, `adb shell date`/설정에서 날짜 +1일 → 숫자 1 감소, 생일 다음 날로 이동 → 다음 일정 항목 반영. 결과를 커밋 메시지 본문에 기록
- [ ] **Step 8:** Commit `feat(life_balance): Glance 소형/중형 위젯`

### Task 11: 상시 알림과 자정 갱신

**Files:**
- Create: `lib/features/ongoing_notification/domain/midnight.dart`, `lib/features/ongoing_notification/data/ongoing_notifier.dart`, `midnight_scheduler.dart`, `lib/app/background/background_dispatcher.dart`
- Modify: `lib/features/widget_sync/data/home_widget_sync.dart` (`syncDerivedOutputs`에 알림 추가)
- Test: `test/features/ongoing_notification/midnight_test.dart`, `notification_text_test.dart`, `test/features/widget_sync/sync_outputs_test.dart`

**Interfaces:**
- Consumes: 계산/포맷/문구 함수, `ProfileRepository`, `AssetLifeTableRepository`, `AssetToneRepository`, `WidgetGateway`
- Produces:
  - `Duration delayUntilNextRefresh(DateTime now)` — 다음 로컬 자정 + 1분까지
  - `String notificationText({required Balance balance, required BalanceUnit unit, required ToneTable tone, required CalendarDate today})` — 보너스면 `notification.bonus_body`
  - `abstract interface class OngoingNotifier { Future<bool> requestPermission(); Future<void> show(String text); Future<void> cancel(); }` + `LocalOngoingNotifier`(채널 id `lb_balance`, 이름 `인생잔고`, `Importance.low`, `ongoing: true`, `autoCancel: false`, `onlyAlertOnce: true`, 알림 id 1)
  - `abstract interface class RefreshScheduler { Future<void> ensureScheduled(DateTime now); }` + `WorkmanagerRefreshScheduler`: one-off `lb_midnight`(`ExistingWorkPolicy.replace`, delay=`delayUntilNextRefresh`) + periodic `lb_hourly`(1시간, `ExistingPeriodicWorkPolicy.keep`, 재부팅 후 복구용)
  - `@pragma('vm:entry-point') void backgroundDispatcher()` — 작업 실행 시 저장소에서 읽어 `syncDerivedOutputs` 호출, `lb_midnight`이면 다음 자정 재예약
  - `Future<void> syncDerivedOutputs({required Profile profile, required AppSettings settings, required LifeTable table, required ToneTable tone, required CalendarDate today, required WidgetGateway widgets, required OngoingNotifier notifier})` (`lib/features/widget_sync/data/home_widget_sync.dart`) — `buildWidgetPayload` → `syncWidget`, 설정 켜짐이면 `show(notificationText(...))`, 꺼짐이면 `cancel`
- [ ] **Step 1:** 실패 테스트: `delayUntilNextRefresh(DateTime(2026,11,25,23,59,30))` == 1분 30초; `(…,0,0,0)` == 24시간 1분. `notificationText` 스토아 비보너스에 `12,345일` 포함, 보너스면 bonus_body 사용. sync 테스트: 알림 켜짐 → `show` 1회, 꺼짐 → `cancel` 1회, 둘 다 위젯 save/refresh 호출
- [ ] **Step 2:** Run `flutter test test/features/ongoing_notification/ test/features/widget_sync/` → FAIL
- [ ] **Step 3:** 구현 (`Workmanager().initialize(backgroundDispatcher)`는 Task 15 bootstrap에서)
- [ ] **Step 4:** Run → PASS
- [ ] **Step 5:** Commit `feat(life_balance): 상시 알림과 자정 갱신`

### Task 12: 온보딩

**Files:**
- Create: `lib/features/profile/presentation/onboarding/onboarding_page.dart`, `onboarding_cubit.dart`, `onboarding_state.dart`
- Test: `test/features/profile/onboarding_cubit_test.dart`, `test/features/profile/onboarding_page_test.dart`

**Interfaces:**
- Consumes: `ProfileRepository`, `JsonLifeTable`, `estimatedLifespanYears`, `ToneId`, `OngoingNotifier.requestPermission`, `syncDerivedOutputs`
- Produces:
  - `enum OnboardingStep { birthDate, sex, country, lifespan, tone, done }`
  - `class OnboardingCubit extends Cubit<OnboardingState> { OnboardingCubit({required ProfileRepository repo, required LifeTable table, required CalendarDate Function() today, required String? deviceCountry, required Future<void> Function(Profile, AppSettings) onComplete}); void setBirthDate(CalendarDate); void setSex(Sex); void setCountry(String); void setManualLifespan(double?); void setTone(ToneId); void next(); void back(); Future<void> complete(); }`
  - 국가 기본값: `deviceCountry`가 테이블에 있으면 그것, 없으면 `KR`
  - 완료 화면: 첫 잔고, 위젯 추가 버튼(`HomeWidget.isRequestPinWidgetSupported()` true면 `HomeWidget.requestPinWidget(qualifiedAndroidName: ...SmallBalanceReceiver)`, 아니면 수동 추가 안내 문구 `onboarding.widget_guide`), 알림 권한 요청
- [ ] **Step 1:** 실패 테스트(bloc_test): 미래 생년월일 거부(오류 상태), 국가 기본값(device `JP` 있으면 JP, `ZZ`면 KR), lifespan 단계 진입 시 `estimatedLifespan` 채워짐, 수동값 입력 후 complete → repo.saveProfile가 manualLifespanYears 포함 호출 + onComplete 호출. 페이지 테스트: 5단계 진행 후 잔고 숫자 표시
- [ ] **Step 2:** Run `flutter test test/features/profile/` → FAIL
- [ ] **Step 3:** 구현. 생년월일 입력은 `showDatePicker`(1900-01-01 ~ 오늘), 성별 라벨 "생명표 기준 성별"
- [ ] **Step 4:** Run → PASS
- [ ] **Step 5:** Commit `feat(life_balance): 온보딩`

### Task 13: 메인 통장 화면과 카이로스 카드

**Files:**
- Create: `lib/features/balance/presentation/passbook_page.dart`, `passbook_cubit.dart`, `passbook_state.dart`, `lib/features/kairos/presentation/kairos_card.dart`
- Modify: `lib/app/app_config.dart`
- Test: `test/features/balance/presentation/passbook_cubit_test.dart`, `passbook_page_test.dart`, `test/features/kairos/kairos_card_test.dart`

**Interfaces:**
- Consumes: Task 2/3 계산, `ToneTable`, `pickPhrase`
- Produces:
  - `enum KairosStatus { preLaunch, launched }`; `AppConfig { final KairosStatus kairosStatus; /* preLaunch */ final String? kairosUrl; /* null */ }`
  - `class PassbookCubit extends Cubit<PassbookState> { PassbookCubit({required Profile profile, required AppSettings settings, required LifeTable table, required ToneTable tone, required CalendarDate Function() today}); void refresh(); }` — state: `birth`, `maturity`, `balance`, `display`, `usedRatio`, `phrases`(화면용 키 → 문장)
  - `KairosCard({required AppConfig config, required ToneTable tone, required CalendarDate today})` — preLaunch+url null: 소개 문구만; preLaunch+url: `kairos.cta` 버튼 → `launchUrl(externalApplication)`; launched: 같은 버튼이 스토어 URL
- [ ] **Step 1:** 실패 테스트: state 값(Task 2 예시 프로필로 display `…일`), 앱이 resumed될 때 `refresh()`로 날짜 변경 반영(today 함수 교체), 보너스면 `main.bonus_notice` 표시. 카이로스: url null이면 버튼 없음
- [ ] **Step 2:** Run → FAIL
- [ ] **Step 3:** 구현. 화면: 계좌 개설일, 잔고(displayLarge), 만기일, 오늘 출금, 진행 막대, 카이로스 카드, 설정 진입 아이콘
- [ ] **Step 4:** Run → PASS
- [ ] **Step 5:** Commit `feat(life_balance): 통장 메인 화면과 카이로스 카드`

### Task 14: 설정 화면

**Files:**
- Create: `lib/features/settings/presentation/settings_page.dart`, `settings_cubit.dart`
- Test: `test/features/settings/settings_cubit_test.dart`, `settings_page_test.dart`

**Interfaces:**
- Consumes: `ProfileRepository`, `OngoingNotifier`, `syncDerivedOutputs`(콜백 `Future<void> Function(Profile, AppSettings) onChanged`), `JsonLifeTable.countries`
- Produces: `SettingsCubit` 메서드 `updateProfile(Profile)`, `setUnit(BalanceUnit)`, `setTone(ToneId)`, `setThemePref(ThemePref)`, `Future<void> setOngoing(bool)` — 켜기 시 `requestPermission()` false면 설정을 false로 유지하고 state에 `permissionDenied=true`
- 화면 항목: 생년월일/성별/국가/기대수명(자동↔수동), 표시 단위, 말투(미리보기 색), 라이트/다크/시스템, 상시 알림 토글, 위젯 추가 안내, 데이터 출처(국가별 source name/year), 오픈소스 라이선스(`showLicensePage`), 폰트 OFL 라이선스는 `LicenseRegistry.addLicense`로 등록
- [ ] **Step 1:** 실패 테스트: 각 변경이 save + onChanged 호출, 권한 거부 시 ongoing false 유지 + permissionDenied, 수동→자동 전환 시 manualLifespanYears null
- [ ] **Step 2:** Run → FAIL
- [ ] **Step 3:** 구현
- [ ] **Step 4:** Run → PASS
- [ ] **Step 5:** Commit `feat(life_balance): 설정 화면`

### Task 15: 앱 조립, 접근성, release 빌드 검증

**Files:**
- Create: `lib/app/bootstrap.dart`, `lib/app/life_balance_app.dart`, `lib/app/di/service_locator.dart`, `README.md`
- Modify: `lib/main.dart`
- Test: `test/app/life_balance_app_test.dart`, `test/app/large_text_test.dart`

**Interfaces:**
- Consumes: 전 Task
- Produces: `Future<Widget> bootstrap(AppConfig config)` — SharedPreferences, 생명표/말투 로드, `Workmanager().initialize(backgroundDispatcher)`, 알림 플러그인 초기화, 프로필 있으면 `syncDerivedOutputs` + `ensureScheduled` 후 메인, 없으면 온보딩. `LifeBalanceApp`은 설정 변경 시 테마(말투×밝기) 즉시 교체, `AppLifecycleState.resumed`에서 `PassbookCubit.refresh()` + `syncDerivedOutputs`
- [ ] **Step 1:** 실패 테스트: 프로필 없음 → 온보딩 첫 화면, 프로필 있음 → 통장 화면. large text: `MediaQuery(textScaler: TextScaler.linear(2.0))`로 통장/설정/온보딩 각 화면 렌더 시 overflow 예외 없음(`tester.takeException()` null), 3말투 × 라이트/다크 조합
- [ ] **Step 2:** Run `flutter test test/app/` → FAIL
- [ ] **Step 3:** 구현 (gateway/notifier/scheduler는 get_it에 interface로 등록해 테스트에서 fake 주입)
- [ ] **Step 4:** Run `cd apps/life_balance && flutter analyze && flutter test && (cd android && ./gradlew :app:testDebugUnitTest) && flutter build appbundle --release` → 모두 성공. release manifest에 `INTERNET` 없음을 `aapt dump permissions` 또는 `bundletool`로 확인
- [ ] **Step 5: 에뮬레이터 종단 수동 검증** (API 34): 신규 설치 → 온보딩 1분 내 완료, 알림 표시 `인생잔고 N일 · 오늘 -1일` 계열, 알림 스와이프 후 앱 재실행 시 재표시, 재부팅 후 1시간 내 알림 복구, 말투 변경 시 위젯/알림 문구와 색 변경, 시스템 글꼴 최대에서 화면 깨짐 없음
- [ ] **Step 6:** README에 실행/테스트/데이터 갱신 방법(`tool/build_life_tables.py`) 기록
- [ ] **Step 7:** Commit `feat(life_balance): 앱 조립과 release 빌드 검증`
