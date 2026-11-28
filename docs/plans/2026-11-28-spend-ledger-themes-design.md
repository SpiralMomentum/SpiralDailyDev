# 지출 위젯 테마 선택 설계

작성일: 2026-11-28. 대상 앱: `apps/spend_ledger` (Android 우선, iOS는 앱 화면만).

## 1. 목적

지금 앱 색은 `ThemeData(colorSchemeSeed: Colors.teal)` 한 줄이고, 홈 위젯 색은 XML에 하드코딩되어 있어 앱과 따로 논다. 다크 모드도 없다. 사용자가 설정에서 테마를 골라 앱과 홈 위젯이 같은 색으로 바뀌게 한다. 이 앱에서 가장 자주 보는 화면은 위젯이므로 위젯이 테마를 따르는 것이 핵심이다.

## 2. 결정된 것 (사용자 결정)

- 테마는 2개: **남색(기본)**, **베이지**. 기존 청록은 뺀다.
- 홈 위젯도 테마를 따른다(설계 논의의 B안).
- 색의 기준은 Dart의 색 표 하나다(접근 1). Kotlin에는 색 사본을 두지 않는다.
- 색 값은 브라우저 시안의 값을 그대로 쓴다(4절). 예외 하나: 베이지 밝음의 primary는 시안의 `#B5653A`가 배경 대비 4.03:1로 글자에 쓰기에 모자라 `#9A5230`(5.43:1)으로 어둡게 했다(작성자 판단).

## 3. 접근

| 안 | 내용 | 결과 |
| --- | --- | --- |
| 1. Dart 색 표 하나 | Dart가 테마별 밝은·어두운 색을 정의, 앱 테마를 만들고 위젯 저장소에 색 값도 넘김. Kotlin은 받은 색을 칠함 | **채택**. 색 기준이 한 곳 |
| 2. Kotlin 리소스 사본 | `values/`·`values-night/`에 같은 색을 따로 적고 Dart는 테마 이름만 넘김 | 기각. 두 곳이 어긋날 위험 |
| 3. `ColorScheme.fromSeed`만 사용 | 시드 하나로 팔레트 자동 생성 | 기각. 고른 시안 색과 일치하지 않음 |

## 4. 색 표

토큰 8개. 값은 `#RRGGBB`.

| 토큰 | 뜻 | 남색 밝음 | 남색 어두움 | 베이지 밝음 | 베이지 어두움 |
| --- | --- | --- | --- | --- | --- |
| background | 화면 배경 | `#F7F8FC` | `#10131A` | `#FBF7F1` | `#18130F` |
| onSurface | 본문 글자 | `#171B24` | `#E0E3EC` | `#221B15` | `#EDE0D4` |
| subtle | 보조 글자(라벨, 기준 시각) | `#4C5468` | `#A3ABBE` | `#6B5A4B` | `#BCA897` |
| primary | 강조, 진행 막대 | `#2F4A7A` | `#9DB8F0` | `#9A5230` | `#F0A77A` |
| track | 진행 막대 바탕 | `#D6DEEE` | `#232B3D` | `#F0DCCB` | `#3A2A1F` |
| card | 카드·칩 배경 | `#E6EBF5` | `#1B2130` | `#F3E9DD` | `#251D17` |
| widgetBackground | 위젯 배경 | `#FFFFFF` | `#181D29` | `#FFFDF9` | `#201913` |
| warning | 예산 경고, 확인 대기 | `#C2410C` | `#FDBA74` | `#B42318` | `#FFB4A8` |

앱 `ColorScheme`은 `ColorScheme.fromSeed(seedColor: primary, brightness: ...)`로 나머지 역할을 채운 뒤, 위 토큰을 해당 역할(`surface`, `onSurface`, `onSurfaceVariant`, `primary`, `surfaceContainer` 등)에 덮어쓴다. 역할 대응은 구현자 판단(위젯 배경 토큰은 앱에서는 쓰지 않아도 된다). 앱 전용 값(`warning`, `track`)은 `ThemeExtension`으로 둔다.

## 5. 설정

- `AppSettings`에 두 값을 추가한다.
  - `themeId`: `navy` | `beige`. 기본 `navy`. 저장된 JSON에 없거나 모르는 값이면 `navy`.
  - `themeMode`: `system` | `light` | `dark`. 기본 `system`.
- 설정 화면에 '테마' 항목을 추가하고, 누르면 테마 선택 화면을 연다.
  - 테마 2개를 카드로 보여 준다. 카드에는 해당 테마의 색 견본(배경, 강조, 경고)과 이름을 넣고, 선택된 카드는 표시한다.
  - 그 아래 밝기를 '시스템 / 밝게 / 어둡게' 세그먼트 버튼으로 고른다.
- 바꾸면 앱에 즉시 적용되고, **위젯도 즉시 다시 그린다**. 위젯 쪽은 추가 배선이 필요 없다: `SettingsCubit._update`가 모든 설정 변경 뒤 `refreshOutputs(deps)`를 부르고, 이 경로가 `widgetEntries`로 위젯을 다시 쓴다. 같은 경로의 예산 알림(`nextBudgetAlert`·`markSent`)은 그대로 둔다. 기간·단계별로 한 번만 보내도록 이미 막혀 있어, 테마 변경이 새 알림을 만들지 않는다(작성자 판단).
- **앱 전역 상태(작성자 판단)**: 지금 `SettingsCubit`은 설정 화면 안에서만 만들어지고 `MaterialApp`은 설정을 읽지 않는다. `SettingsCubit`을 앱 최상단(`SpendLedgerApp`)으로 올려 `MaterialApp`의 `theme`·`darkTheme`·`themeMode`가 이것을 따르게 하고, 설정 화면은 같은 인스턴스를 쓴다. `bootstrap`이 첫 프레임 전에 설정을 읽어 초기 상태로 넘겨, 시작할 때 다른 테마가 잠깐 보이지 않게 한다. 헤드리스 수집 엔진은 UI가 없으므로 이 변경과 무관하다.

## 6. 위젯 색 전달

- `widgetEntries`가 기존 문자열에 더해 색 키를 넣는다. 각 토큰마다 밝은 값과 어두운 값 두 키(예: `color.onSurface.light`, `color.onSurface.dark`)와 `themeMode` 키 하나. 값은 `#AARRGGBB` 또는 `#RRGGBB` 문자열. 키 이름은 구현자가 정하되 Dart와 Kotlin 테스트가 같은 목록을 검증한다.
- 백그라운드 수집 엔진도 같은 `widgetEntries`를 거치므로 수집 시에도 색이 함께 저장된다.
- Kotlin(`WidgetTexts` 옆 순수 로직)이 색 값을 파싱한다. 키가 없거나 파싱에 실패하면 남색 테마 값으로 대체하지 않고 **레이아웃 XML의 기본색**(남색 밝음 값으로 바꿔 둔다)을 그대로 둔다. 위젯이 빈 화면이 되지 않게 하기 위함이다.
- 밝음·어두움 선택:
  - `themeMode`가 `light`/`dark`면 그 값으로 고정해 칠한다.
  - `system`이면 API 31 이상에서는 `RemoteViews.setColorInt(viewId, method, light, dark)`로 두 값을 함께 넘겨 시스템 다크 모드 전환을 런처가 처리하게 한다. API 26~30에서는 그릴 때의 시스템 야간 모드로 하나를 골라 칠한다(시스템 다크 모드를 바꾼 뒤 다음 위젯 갱신 전까지 이전 밝기로 남을 수 있음, 허용.). 8절의 '테마 변경 후 이전 색 유지'는 앱에서 테마를 바꾼 경우를 말하며, 그때는 위 경로로 항상 다시 그린다. 시스템 설정 변경 신호(`ACTION_CONFIGURATION_CHANGED`) 수신은 범위 밖(작성자 판단).
- 칠할 대상: 모든 글자색(본문·보조·강조·경고), 진행 막대 두 개의 진행·바탕색, 위젯 둥근 배경. 둥근 배경은 minSdk 26에서도 색을 바꿀 수 있도록 배경 레이어(예: 뒤에 깔린 `ImageView`에 흰 둥근 모양 + 색 필터) 방식으로 만든다. 방법은 구현자 판단.

## 7. 범위 밖

- iOS 위젯(없음). iOS 앱 화면은 Flutter 테마를 그대로 따르므로 별도 작업 없음.
- 글자 크기·간격 체계 정리, 화면 레이아웃 변경.
- 사용자가 색을 직접 고르는 기능, 테마 추가.

## 8. 실패로 보는 경우

- 앱과 위젯 색이 다르게 보이는 상태가 남는 것(테마 변경 후 위젯이 이전 색 유지).
- 다크 모드에서 글자와 배경 대비가 낮아 금액이 읽기 어려운 것. 글자로 쓰는 토큰(onSurface, subtle, primary, warning)은 background와 widgetBackground 모두에 대해 4.5:1 이상이어야 한다. 4절 값은 작성 시 계산으로 최저 4.9:1(남색 밝음 warning)이며, 구현자가 테스트로 고정한다.
- 기존 설치본의 설정이 깨져 앱이 시작 오류 화면으로 가는 것(테마 키 없는 JSON).

## 9. 검증

- Dart 단위 테스트: 색 표 값, `AppSettings` JSON 왕복과 기본값, `widgetEntries`의 색 키, 대비 4.5:1, 테마 변경 시 위젯 저장 호출(가짜 `WidgetGateway`로 확인. iOS는 `NoopWidgetGateway`라 실제 저장은 Android에서만 일어남).
- 위젯 테스트: 설정에서 테마·밝기를 바꾸면 `MaterialApp`의 테마가 바뀌는지, 저장된 설정이 첫 프레임에 적용되는지.
- Kotlin JVM 테스트: 색 문자열 파싱, 키 누락·잘못된 값 처리, `themeMode`별 선택.
- 에뮬레이터: 두 테마 × 밝음/어두움에서 앱 홈과 위젯 3종 스크린샷.

## 10. 구현자 판단으로 남긴 것

- 토큰과 `ColorScheme` 역할의 대응, `ThemeExtension` 이름.
- 위젯 색 키 이름, 배경 색칠 방식.
- 테마 선택 화면의 세부 배치.
- `tabularFigures`를 테마 파일로 옮길지.
