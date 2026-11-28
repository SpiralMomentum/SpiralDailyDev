# 지출 위젯 테마 선택 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 설정에서 테마(남색·베이지)와 밝기(시스템·밝게·어둡게)를 고르면 앱과 Android 홈 위젯 3종이 같은 색으로 바뀐다.

**Architecture:** 순수 Dart 색 표(`features/theme/domain`)가 유일한 색 기준이다. 앱은 이 표로 `ThemeData`를 만들고, `widgetEntries`는 같은 표의 위젯용 색을 home_widget 저장소에 문자열로 넣는다. Kotlin 위젯은 그 문자열을 파싱해 `RemoteViews`로 칠한다. `SettingsCubit`을 앱 최상단으로 올려 `MaterialApp`이 설정을 따른다.

**Tech Stack:** Flutter 3.41.2 / Dart 3.11.0, flutter_bloc, mocktail, home_widget ^0.10.0, Kotlin(JUnit JVM 테스트).

**Spec:** `docs/plans/2026-11-28-spend-ledger-themes-design.md`

## Global Constraints

- 앱 경로 `apps/spend_ledger`. 명령은 이 디렉터리에서 실행한다.
- 도메인 레이어(`lib/features/*/domain`)는 `package:flutter`를 import하지 않는다. 함수는 순수 함수로 쓴다.
- build_runner 금지. 모킹은 mocktail.
- 테마 2개: `navy`(기본), `beige`. 밝기 3개: `system`(기본), `light`, `dark`. 저장 JSON 키 `themeId`, `themeMode`. 없거나 모르는 값이면 기본값.
- 색 값은 설계 4절 표 그대로(베이지 밝음 primary `#9A5230`).
- 글자 토큰(onSurface, subtle, primary, warning)은 background·widgetBackground 각각에 대해 대비 4.5:1 이상.
- 위젯 색 키(Dart·Kotlin 공통, 정확히 이 이름): `theme.mode` = `system`|`light`|`dark`, 그리고 6개 토큰 `widgetBackground`, `onSurface`, `subtle`, `primary`, `track`, `warning` 각각에 `color.<token>.light`, `color.<token>.dark`. 값은 `#AARRGGBB` 대문자 16진수(예 `#FF2F4A7A`).
- 커밋 메시지 끝: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. 관계없는 미추적 파일(`apps/*/store_listing.json`, `apps/color_snap/`, `apps/life_balance/`, `tools/store/`, `.superpowers/`)은 `git add` 하지 않는다. 파일을 경로로 지정해 add한다.
- 한국어 UI 문구, 이모지 없음.

## Review Focus

1. 기존 설치본: 저장된 설정 JSON에 `themeId`·`themeMode`가 없음 → 남색·시스템으로 시작, 시작 오류 화면으로 가지 않음 (Task 2 테스트).
2. 위젯 저장소에 색 키가 아직 없음(업데이트 직후, 앱을 열기 전 위젯이 먼저 그려짐) → 위젯은 레이아웃 XML 기본색으로 그려지고 비지 않음 (Task 4 테스트).
3. 테마를 바꾼 직후 → 앱과 위젯이 함께 새 색 (Task 3 테스트: 저장 후 refresh 호출, Task 2 테스트: 엔트리에 새 색).
4. 첫 프레임 → 저장된 테마로 바로 그려짐(남색이 잠깐 보이지 않음) (Task 3 테스트).
5. 금액 숨김 켬 + 어두운 테마 → 숨김 문자열과 색 키가 함께 들어감, 서로 간섭 없음 (Task 2 테스트).

---

### Task 1: 색 표와 앱 테마

**Files:**
- Create: `lib/features/theme/domain/palette.dart`
- Create: `lib/features/theme/presentation/app_theme.dart`
- Modify: `lib/features/ledger/presentation/tx_tile.dart` (`tabularFigures`를 `app_theme.dart`로 옮기고 기존 import 경로 갱신)
- Test: `test/features/theme/palette_test.dart`, `test/features/theme/app_theme_test.dart`

**Interfaces:**
- Produces (domain, Flutter 없음):
  - `enum AppThemeId { navy, beige }` — `static AppThemeId fromName(String? name)` (모르면 `navy`), 화면 이름 `String get label` (`'남색'`, `'베이지'`).
  - `enum AppThemeMode { system, light, dark }` — `static AppThemeMode fromName(String? name)` (모르면 `system`).
  - `final class Palette` — `int` ARGB 필드 8개: `background, onSurface, subtle, primary, track, card, widgetBackground, warning`. const 생성자.
  - `final class ThemeColors { final Palette light; final Palette dark; }`
  - `ThemeColors themeColors(AppThemeId id)`
  - `double contrastRatio(int argbA, int argbB)` — WCAG 2.x 상대 휘도 공식.
- Produces (presentation):
  - `ThemeData buildAppTheme(AppThemeId id, Brightness brightness)`
  - `class SpendColors extends ThemeExtension<SpendColors>` — 필드 `Color warning, track`. `buildAppTheme`이 extensions에 넣는다.
  - `const TextStyle tabularFigures` (기존 값 그대로 이동)

- [ ] **Step 1: 실패하는 테스트 작성** (`palette_test.dart`)

```dart
test('남색 밝음 primary와 베이지 밝음 primary', () {
  expect(themeColors(AppThemeId.navy).light.primary, 0xFF2F4A7A);
  expect(themeColors(AppThemeId.beige).light.primary, 0xFF9A5230);
});
test('모든 글자 토큰은 배경·위젯 배경 대비 4.5 이상', () {
  for (final id in AppThemeId.values) {
    final c = themeColors(id);
    for (final p in [c.light, c.dark]) {
      for (final fg in [p.onSurface, p.subtle, p.primary, p.warning]) {
        expect(contrastRatio(fg, p.background), greaterThanOrEqualTo(4.5));
        expect(contrastRatio(fg, p.widgetBackground), greaterThanOrEqualTo(4.5));
      }
    }
  }
});
test('contrastRatio 흑백은 21', () {
  expect(contrastRatio(0xFF000000, 0xFFFFFFFF), closeTo(21, 0.01));
});
test('fromName 기본값', () {
  expect(AppThemeId.fromName(null), AppThemeId.navy);
  expect(AppThemeId.fromName('teal'), AppThemeId.navy);
  expect(AppThemeMode.fromName('dark'), AppThemeMode.dark);
  expect(AppThemeMode.fromName('x'), AppThemeMode.system);
});
```

설계 4절 표의 32개 값 전부를 테스트 표로 검증하는 케이스도 추가한다(값을 표에서 그대로 옮긴다).

- [ ] **Step 2: 실행해 실패 확인** — `flutter test test/features/theme/palette_test.dart` → 컴파일 실패(정의 없음).

- [ ] **Step 3: `palette.dart` 구현** — 설계 4절 표를 const로 옮긴다. `contrastRatio`는 채널별 `c <= 0.03928 ? c/12.92 : pow((c+0.055)/1.055, 2.4)`, 휘도 `0.2126R+0.7152G+0.0722B`, `(L1+0.05)/(L2+0.05)` (큰 값이 L1).

- [ ] **Step 4: 실패하는 테스트 작성** (`app_theme_test.dart`)

```dart
test('buildAppTheme은 색 표를 따른다', () {
  final t = buildAppTheme(AppThemeId.beige, Brightness.dark);
  final p = themeColors(AppThemeId.beige).dark;
  expect(t.brightness, Brightness.dark);
  expect(t.colorScheme.primary, Color(p.primary));
  expect(t.colorScheme.surface, Color(p.background));
  expect(t.colorScheme.onSurface, Color(p.onSurface));
  expect(t.colorScheme.onSurfaceVariant, Color(p.subtle));
  expect(t.extension<SpendColors>()!.warning, Color(p.warning));
  expect(t.extension<SpendColors>()!.track, Color(p.track));
});
```

- [ ] **Step 5: `app_theme.dart` 구현** — `ColorScheme.fromSeed(seedColor: Color(p.primary), brightness: b).copyWith(primary, surface, onSurface, onSurfaceVariant, surfaceContainer: card, surfaceContainerHighest: track)`, `useMaterial3: true`, `scaffoldBackgroundColor: surface`. `tabularFigures`를 옮긴다.

- [ ] **Step 6: 테스트 통과 확인** — `flutter test test/features/theme/` → PASS. `flutter analyze` → 0 issues.

- [ ] **Step 7: 커밋**

```bash
git add lib/features/theme test/features/theme lib/features/ledger/presentation/tx_tile.dart <tabularFigures import를 바꾼 파일들>
git commit -m "feat(spend_ledger): 테마 색 표와 앱 테마 생성"
```

### Task 2: 설정 값과 위젯 색 엔트리

**Files:**
- Modify: `lib/features/settings/domain/app_settings.dart`
- Modify: `lib/features/settings/presentation/settings_cubit.dart`
- Modify: `lib/features/widget_sync/domain/widget_entries.dart`
- Modify: `lib/features/ingest/domain/ingest.dart:184` (호출부)
- Test: `test/features/settings/app_settings_test.dart`(없으면 생성), `test/features/settings/settings_cubit_test.dart`, `test/features/widget_sync/widget_entries_test.dart`

**Interfaces:**
- Consumes: Task 1의 `AppThemeId`, `AppThemeMode`, `themeColors`.
- Produces:
  - `AppSettings.themeId: AppThemeId` (기본 `navy`), `AppSettings.themeMode: AppThemeMode` (기본 `system`), `copyWith(themeId:, themeMode:)`, JSON 키 `themeId`·`themeMode`(enum `name`), `props`에 포함.
  - `SettingsCubit.setTheme(AppThemeId id)`, `SettingsCubit.setThemeMode(AppThemeMode mode)` — 기존 `_update` 경로(저장 후 refresh).
  - `widgetEntries(LedgerSummary s, {required bool hideAmounts, required DateTime asOf, required AppThemeId themeId, required AppThemeMode themeMode})` — 기존 키에 더해 Global Constraints의 13개 색 키.
  - `String argbHex(int argb)` → `#AARRGGBB` 대문자 (widget_entries.dart에 공개 함수로).

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
// app_settings_test.dart
test('테마 키 없는 기존 JSON은 남색·시스템', () {
  final s = AppSettings.fromJson({'startDay': 5});
  expect(s.themeId, AppThemeId.navy);
  expect(s.themeMode, AppThemeMode.system);
  expect(s.startDay, 5);
});
test('JSON 왕복', () {
  const s = AppSettings(themeId: AppThemeId.beige, themeMode: AppThemeMode.dark);
  expect(AppSettings.fromJson(s.toJson()), s);
  expect(s.toJson()['themeId'], 'beige');
  expect(s.toJson()['themeMode'], 'dark');
});
test('모르는 값은 기본값', () {
  final s = AppSettings.fromJson({'themeId': 'teal', 'themeMode': 1});
  expect(s.themeId, AppThemeId.navy);
  expect(s.themeMode, AppThemeMode.system);
});

// widget_entries_test.dart
test('색 키 13개와 값', () {
  final e = widgetEntries(summary, hideAmounts: false, asOf: asOf,
      themeId: AppThemeId.beige, themeMode: AppThemeMode.dark);
  expect(e['theme.mode'], 'dark');
  expect(e['color.primary.light'], '#FF9A5230');
  expect(e['color.primary.dark'], '#FFF0A77A');
  expect(e['color.widgetBackground.light'], '#FFFFFDF9');
  expect(e.keys.where((k) => k.startsWith('color.')).length, 12);
});
test('금액 숨김과 색 키가 함께 들어간다', () {
  final e = widgetEntries(summary, hideAmounts: true, asOf: asOf,
      themeId: AppThemeId.navy, themeMode: AppThemeMode.system);
  expect(e['total'], '');
  expect(e['color.onSurface.dark'], '#FFE0E3EC');
  expect(e['theme.mode'], 'system');
});
test('argbHex', () => expect(argbHex(0xFF2F4A7A), '#FF2F4A7A'));

// settings_cubit_test.dart
test('setTheme은 저장 후 refresh를 부른다', () async {
  // 기존 테스트의 fake 리포지토리·refresh 카운터 패턴을 따른다
  await cubit.setTheme(AppThemeId.beige);
  expect(savedSettings.themeId, AppThemeId.beige);
  expect(refreshCalls, 1);
  expect(cubit.state.settings.themeId, AppThemeId.beige);
});
```

`setThemeMode`도 같은 형태로 하나 추가한다.

- [ ] **Step 2: 실행해 실패 확인** — `flutter test test/features/settings test/features/widget_sync` → 컴파일 실패.

- [ ] **Step 3: 구현** — `AppSettings`에 필드 추가(fromJson은 `AppThemeId.fromName(json['themeId'] as String?)`처럼 타입이 아니면 null로 취급). `widgetEntries`는 `themeColors(themeId)`의 light/dark에서 6개 토큰을 꺼내 `argbHex`로 넣는다. `ingest.dart` 호출부에 `themeId: settings.themeId, themeMode: settings.themeMode` 추가. 기존 `widgetEntries` 호출 테스트도 새 인자로 고친다.

- [ ] **Step 4: 테스트 통과 확인** — `flutter test` 전체 → PASS. `flutter analyze` → 0 issues.

- [ ] **Step 5: 커밋**

```bash
git add <수정·생성한 파일 경로들>
git commit -m "feat(spend_ledger): 테마 설정 값과 위젯 색 엔트리"
```

### Task 3: 앱 전역 테마 적용과 테마 선택 화면

**Files:**
- Modify: `lib/app/bootstrap.dart` (`bootstrap()` 반환에 설정 추가)
- Modify: `lib/main.dart`
- Modify: `lib/app/spend_ledger_app.dart`
- Modify: `lib/features/settings/presentation/settings_cubit.dart` (초기 설정 인자)
- Modify: `lib/features/settings/presentation/settings_page.dart` (큐빗 생성 제거, '테마' 항목 추가)
- Create: `lib/features/settings/presentation/theme_page.dart`
- Modify: 테스트 중 `SettingsPage`를 직접 띄우는 것(`test/features/settings/settings_page_test.dart` 등)
- Test: `test/app/spend_ledger_app_test.dart`, `test/features/settings/theme_page_test.dart`

**Interfaces:**
- Consumes: Task 1 `buildAppTheme`, `AppThemeId.label`, `themeColors`; Task 2 `setTheme`, `setThemeMode`, `AppSettings.themeId/themeMode`.
- Produces:
  - `SettingsCubit(repo, refresh, {AndroidBridge bridge, AppSettings? initial})` — `initial`이 있으면 시작 상태가 `SettingsState(settings: initial, loading: false)`.
  - `Future<(IngestDeps, String?, AppSettings)> bootstrap()` — 설정 읽기 실패 시 `const AppSettings()`로 대체하고 `debugPrint`로 타입만 기록.
  - `SpendLedgerApp({..., AppSettings initialSettings = const AppSettings()})` — `BlocProvider<SettingsCubit>`를 `MaterialApp` 위에 두고, `BlocBuilder`(buildWhen: themeId 또는 themeMode 변경)로 `theme: buildAppTheme(id, Brightness.light)`, `darkTheme: buildAppTheme(id, Brightness.dark)`, `themeMode`(AppThemeMode → Flutter `ThemeMode`) 지정.
  - `SettingsPage`는 `context.read<SettingsCubit>()`를 쓴다(생성하지 않음).
  - `ThemePage` — 테마 카드 2개(이름 + 배경·강조·경고 색 견본 3개, 선택 표시는 체크 아이콘과 강조 테두리), 아래 `SegmentedButton<AppThemeMode>`('시스템', '밝게', '어둡게'). 설정 화면의 '테마' ListTile(부제: 예 `남색 · 시스템`)에서 연다.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
// spend_ledger_app_test.dart (기존 fake deps 패턴 사용)
testWidgets('저장된 테마로 첫 프레임을 그린다', (t) async {
  await t.pumpWidget(SpendLedgerApp(deps: deps,
      initialSettings: const AppSettings(themeId: AppThemeId.beige, themeMode: AppThemeMode.light)));
  final app = t.widget<MaterialApp>(find.byType(MaterialApp));
  expect(app.theme!.colorScheme.primary, const Color(0xFF9A5230));
  expect(app.themeMode, ThemeMode.light);
});
testWidgets('설정에서 테마를 바꾸면 MaterialApp 테마가 바뀐다', (t) async {
  // 앱 → 설정 → 테마 → '베이지' 탭 → pumpAndSettle
  // expect MaterialApp.theme.colorScheme.primary == Color(0xFF9A5230)
  // expect fake settings 저장소의 themeId == beige
});

// theme_page_test.dart
testWidgets('밝기 세그먼트 선택이 저장된다', (t) async {
  // '어둡게' 탭 → cubit.state.settings.themeMode == AppThemeMode.dark
});
testWidgets('선택된 테마 카드에 체크 표시', (t) async { /* 남색 카드에 Icons.check */ });
```

- [ ] **Step 2: 실행해 실패 확인** — `flutter test test/app/spend_ledger_app_test.dart test/features/settings/theme_page_test.dart` → FAIL.

- [ ] **Step 3: 구현** — 위 Interfaces대로. `main.dart`는 세 값을 받아 `initialSettings`로 넘긴다. 하드코딩된 `Colors.teal` 제거. 설정 화면 하위 화면(`_push`)은 그대로 `BlocProvider.value`를 써도 되고, 앱 최상단 provider가 있으므로 제거해도 된다(구현자 판단).

- [ ] **Step 4: 기존 테스트 정리** — `SettingsPage`를 직접 띄우던 테스트를 `BlocProvider<SettingsCubit>`로 감싼다. `flutter test` 전체 → PASS. `flutter analyze` → 0 issues.

- [ ] **Step 5: 커밋**

```bash
git add <수정·생성한 파일 경로들>
git commit -m "feat(spend_ledger): 앱 전역 테마 적용과 테마 선택 화면"
```

### Task 4: Android 위젯 색칠

**Files:**
- Create: `android/app/src/main/kotlin/com/spiralmomentum/spend_ledger/WidgetColors.kt`
- Modify: `android/app/src/main/kotlin/com/spiralmomentum/spend_ledger/SpendWidgetProviders.kt`
- Modify: `android/app/src/main/res/layout/widget_small.xml`, `widget_medium.xml`, `widget_large.xml`
- Modify: `android/app/src/main/res/drawable/widget_background.xml`
- Test: `android/app/src/test/kotlin/com/spiralmomentum/spend_ledger/WidgetColorsTest.kt`

**Interfaces:**
- Consumes: Task 2의 색 키(Global Constraints).
- Produces (순수 Kotlin, Android 클래스 없음):
  - `enum class WidgetMode { SYSTEM, LIGHT, DARK }`
  - `data class WidgetPalette(val widgetBackground: Int, val onSurface: Int, val subtle: Int, val primary: Int, val track: Int, val warning: Int)`
  - `data class WidgetColors(val mode: WidgetMode, val light: WidgetPalette, val dark: WidgetPalette)`
  - `fun widgetColors(data: Map<String, String?>): WidgetColors?` — 12개 색 키 중 하나라도 없거나 파싱 실패면 `null`. `theme.mode`가 없거나 모르는 값이면 `SYSTEM`.
  - `fun parseArgb(s: String?): Int?` — `#AARRGGBB`·`#RRGGBB`(알파 FF) 허용, 그 외 null. `android.graphics.Color` 쓰지 않음(JVM 테스트).
  - `fun WidgetColors.pick(nightNow: Boolean): WidgetPalette` — LIGHT→light, DARK→dark, SYSTEM→nightNow에 따라.

- [ ] **Step 1: 실패하는 테스트 작성** (`WidgetColorsTest.kt`)

```kotlin
@Test fun parsesEightAndSixDigit() {
    assertEquals(0xFF2F4A7A.toInt(), parseArgb("#FF2F4A7A"))
    assertEquals(0xFF2F4A7A.toInt(), parseArgb("#2F4A7A"))
    assertNull(parseArgb("2F4A7A")); assertNull(parseArgb("#GG0000")); assertNull(parseArgb(null))
}
@Test fun missingKeyGivesNull() { assertNull(widgetColors(fullData() - "color.track.dark")) }
@Test fun emptyDataGivesNull() { assertNull(widgetColors(emptyMap())) }
@Test fun modeAndPick() {
    val c = widgetColors(fullData() + ("theme.mode" to "dark"))!!
    assertEquals(WidgetMode.DARK, c.mode)
    assertEquals(c.dark, c.pick(nightNow = false))
    val s = widgetColors(fullData() + ("theme.mode" to "weird"))!!
    assertEquals(WidgetMode.SYSTEM, s.mode)
    assertEquals(s.light, s.pick(nightNow = false)); assertEquals(s.dark, s.pick(nightNow = true))
}
@Test fun keyNamesMatchDart() {
    // Global Constraints의 12개 키 이름을 리터럴로 나열해 fullData()와 같음을 확인
}
```

`fullData()`는 남색 값(설계 4절)으로 12개 키를 채운다.

- [ ] **Step 2: 실행해 실패 확인** — `cd android && ./gradlew :app:testDebugUnitTest --tests '*WidgetColorsTest'` → 컴파일 실패.

- [ ] **Step 3: `WidgetColors.kt` 구현** → Step 2 명령 PASS.

- [ ] **Step 4: 레이아웃 수정**
  - 세 레이아웃의 루트를 `FrameLayout`(id `widget_root` 유지)으로 바꾸고, 첫 자식으로 `ImageView` id `widget_bg`(match_parent, `android:src="@drawable/widget_background"`, `scaleType="fitXY"`), 둘째 자식으로 기존 `LinearLayout` 내용을 둔다. 클릭 대상 `widget_root`·`widget_pending`은 유지.
  - `widget_background.xml`의 solid 색을 `#FFFFFFFF`(흰색, 색 필터로 칠함)로 바꾼다.
  - id 없는 라벨 TextView에 id를 붙인다(예 `widget_label_total`, 대형의 목록 제목이 별도 뷰면 그것도).
  - XML 기본색을 남색 밝음 값으로 바꾼다: 본문 `#171B24`, 보조(라벨·기준 시각·오늘·하루·목록) `#4C5468`, 강조(ratio) `#2F4A7A`, 경고(pending) `#C2410C`, 배경 이미지 `android:tint="#FFFFFF"` 없이 흰색 그대로. 진행 막대는 `android:progressTint="#2F4A7A"`, `android:progressBackgroundTint="#D6DEEE"`.

- [ ] **Step 5: 칠하기 연결** (`SpendWidgetProviders.kt`)
  - `onUpdate`에서 `widgetColors(...)`가 null이면 색을 건드리지 않는다(XML 기본색).
  - null이 아니면 뷰 id별 역할(배경 `widget_bg`→widgetBackground `setColorFilter`, `widget_total`→onSurface, 라벨·`widget_today`·`widget_daily`·`widget_as_of`·`widget_top`·`widget_recent`→subtle, `widget_ratio`→primary, `widget_pending`→warning, 텍스트는 `setTextColor`)로 칠한다. 크기별로 레이아웃에 있는 id만 칠한다.
  - API 31 이상이고 mode가 SYSTEM이면 `RemoteViews.setColorInt(id, method, light, dark)`로 두 값을 넘긴다. 진행 막대는 API 31 이상에서 `setColorStateList(id, "setProgressTintList", ...)`와 `"setProgressBackgroundTintList"`(SYSTEM이면 light/dark 두 값을 받는 오버로드). 그 밖(API 26~30 또는 LIGHT/DARK 고정)은 `pick(nightNow)`의 값 하나로 `setTextColor`/`setInt(id, "setColorFilter", c)`를 쓴다. `nightNow`는 `context.resources.configuration.uiMode and UI_MODE_NIGHT_MASK == UI_MODE_NIGHT_YES`.
  - **Ruling(계획 작성자)**: API 26~30에서는 진행 막대 색을 RemoteViews로 바꿀 공개 방법이 없어 XML 기본(남색 밝음)으로 둔다. 설계 6절 "진행 막대 두 개의 진행·바탕색"을 API 31 이상으로 한정한다. 틀리면 구형 기기에서 베이지·어두운 테마의 막대만 남색으로 보인다.

- [ ] **Step 6: 확인** — `cd android && ./gradlew :app:testDebugUnitTest` → 전체 PASS. `flutter build apk --debug` → 성공. `flutter test` → PASS.

- [ ] **Step 7: 커밋**

```bash
git add android/app/src/main/kotlin/com/spiralmomentum/spend_ledger/WidgetColors.kt android/app/src/main/kotlin/com/spiralmomentum/spend_ledger/SpendWidgetProviders.kt android/app/src/main/res/layout/widget_small.xml android/app/src/main/res/layout/widget_medium.xml android/app/src/main/res/layout/widget_large.xml android/app/src/main/res/drawable/widget_background.xml android/app/src/test/kotlin/com/spiralmomentum/spend_ledger/WidgetColorsTest.kt
git commit -m "feat(spend_ledger): 홈 위젯 테마 색칠"
```

### 마무리 확인 (컨트롤러)

에뮬레이터(`emulator-5554`, API 34)에 설치해 남색·베이지 × 밝게·어둡게 4조합으로 앱 홈과 위젯 3종을 스크린샷으로 확인하고, 시스템 다크 모드 전환 시 위젯이 따라가는지(`theme.mode=system`) 확인한다. README 5.5절에 테마 설정 한 줄을 추가한다.
