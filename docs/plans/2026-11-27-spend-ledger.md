# 지출 위젯 가계부 (spend_ledger) 1단계 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 결제 문자 원문을 받아 범용 파싱·분류·집계하고 확인 알림과 후보 리스트로 확정하는 Flutter 앱의 코어와 화면을 `apps/spend_ledger`에 만들고, iOS 단축어 → App Intent → 헤드리스 Dart 수집 경로를 실기기 검증용으로 구현한다.

**Architecture:** 모든 수집 경로는 Dart `ingestMessage(RawMessage, IngestDeps)` 하나로 모인다. 필터·파싱·분류·중복/취소 매칭·요약은 Flutter 의존 없는 순수 함수(domain)이고, 저장(sqflite_sqlcipher 암호화 DB)·알림(flutter_local_notifications)·키 저장(flutter_secure_storage)은 data 계층 인터페이스 뒤에 둔다. iOS App Intent는 헤드리스 FlutterEngine으로 Dart 진입점 `iosIngestMain`을 실행한다.

**Tech Stack:** Flutter 3.41.2 / Dart 3.11.0, flutter_bloc, get_it, equatable, intl, sqflite_sqlcipher, sqflite_common, flutter_secure_storage, flutter_local_notifications, mocktail, bloc_test, sqflite_common_ffi(테스트); iOS Swift App Intents (iOS 17).

**Spec:** `docs/plans/2026-11-27-spend-ledger-design.md` (원본 요구사항 `doc/26_Q4/가계부.md`)

## Global Constraints

- 앱 경로 `apps/spend_ledger`, iOS 번들 ID `com.spiralmomentum.spendLedger`, Android applicationId `com.spiralmomentum.spend_ledger`, 표시 이름 `지출 위젯`
- iOS 최소 17.0, Android minSdk 26
- 본인용 배포. 스토어·CI(release-all.yaml) 등록, store_listing, 개인정보처리방침 작업 없음
- 네트워크 호출·분석·크래시 SDK 금지. Android manifest에 `INTERNET` 권한 추가 금지
- build_runner/코드 생성 금지(freezed, drift, json_serializable, mockito). 모킹은 mocktail
- domain 계층은 `package:flutter` import 금지 (헤드리스 엔진·백그라운드 isolate 재사용)
- 순수 함수·불변 값 우선. 부수효과는 data 계층과 `lib/app`에만
- 금액은 원 단위 `int`(부호 있음). 일시는 로컬 `DateTime`, DB에는 `millisecondsSinceEpoch`
- 금융 데이터는 암호화 DB에만 저장. shared_preferences에 거래·이름·필터 저장 금지
- DB 키는 32바이트 무작위, flutter_secure_storage에 iOS `KeychainAccessibility.first_unlock`으로 저장 (잠금 상태 백그라운드 수집 대비)
- 확인 알림 문구(지출): `{가맹점}에서 {금액}원 지출이 있었던 것 같아요. 지출에 포함할까요?` — 가맹점이 비면 `어딘가에서`. 금액은 `#,###` 형식
- 확인 알림 문구(환불, 음수): `{가맹점} 환불 {금액}원을 지출에서 뺄까요?` (금액은 절댓값)
- 알림 액션 라벨 `포함`, `제외`. UI 언어 한국어 단일, 이모지 금지
- 커밋 형식 `feat(spend_ledger): ...`, 끝에 `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`
- 이 단계에서 home_widget·네이티브 위젯·Android 알림 리스너는 만들지 않는다(2·3단계). 위젯 페이로드는 순수 함수까지만 만든다

## Review Focus

1. 입금 문자("입금 50,000")가 금액 폴백 때문에 지출 승인으로 잡힘 → 기본 제외 키워드 `입금`으로 버려져야 함 (Task 2 `default rules drop deposit`)
2. 잔액·누적 금액이 결제 금액보다 먼저 나오는 문자 → 결제 금액만 읽어야 함 (Task 3 `skips balance before amount`)
3. 12월 31일 23:50 결제 문자를 1월 1일에 수신 → 연도가 전년으로 잡혀야 함 (Task 3 `year rollover`)
4. 같은 결제 문자가 단축어 재실행으로 두 번 수신 → 두 번째는 duplicate, 알림 없음 (Task 5 `duplicate within 5 minutes`)
5. 알림 '포함'을 같은 거래에 두 번 누름(알림 중복 탭) 또는 이미 취소된 거래에 응답 → 상태가 cancelled에서 included로 되돌아가지 않아야 함 (Task 8 `resolve ignores cancelled`)

---

## File Structure

```
apps/spend_ledger/
  pubspec.yaml, analysis_options.yaml
  lib/main.dart
  lib/app/{bootstrap.dart, spend_ledger_app.dart, ingest_entry.dart, di/service_locator.dart}
  lib/features/ledger/domain/{transaction.dart, money_format.dart, decide.dart, merchant_match.dart}
  lib/features/ledger/data/{ledger_database.dart, sql_ledger_repository.dart, db_key.dart}
  lib/features/ledger/presentation/{candidates_page.dart, candidates_cubit.dart, edit_page.dart, edit_cubit.dart}
  lib/features/message_filter/domain/{raw_message.dart, filter_rule.dart, name_registry.dart, filter.dart}
  lib/features/parsing/domain/{parsed_message.dart, parser.dart, signature.dart, format_hint.dart}
  lib/features/parsing/data/sql_format_hint_repository.dart
  lib/features/parsing/presentation/parse_test_page.dart
  lib/features/budget/domain/{period.dart, summary.dart, budget_alert.dart}
  lib/features/budget/presentation/{home_page.dart, home_cubit.dart}
  lib/features/widget_sync/domain/widget_entries.dart
  lib/features/settings/domain/app_settings.dart
  lib/features/settings/data/sql_settings_repository.dart
  lib/features/settings/presentation/{settings_page.dart, settings_cubit.dart, filters_page.dart, names_page.dart}
  lib/features/confirm_notification/data/local_confirm_notifier.dart
  lib/features/confirm_notification/domain/notification_text.dart
  lib/features/ingest/domain/ingest.dart
  lib/features/ingest/presentation/{shortcut_guide_page.dart, diagnostics_page.dart}
  test/fixtures/messages.dart
  test/acceptance/acceptance_test.dart
  test/support/{fakes.dart, memory_db.dart}
  ios/Runner/{RecordPaymentMessageIntent.swift, HeadlessIngest.swift, IngestDiagnostics.swift}
```

---

### Task 1: 앱 생성과 빌드 설정

**Files:**
- Create: `apps/spend_ledger/` (flutter create), `apps/spend_ledger/analysis_options.yaml`
- Modify: `apps/spend_ledger/pubspec.yaml`, `ios/Podfile`, `ios/Runner.xcodeproj/project.pbxproj`, `ios/Runner/Info.plist`, `android/app/build.gradle(.kts)`, `android/app/src/main/AndroidManifest.xml`
- Test: `apps/spend_ledger/test/app/smoke_test.dart`

**Interfaces:**
- Produces: 빌드 가능한 빈 앱, `SpendLedgerApp` 위젯(`lib/app/spend_ledger_app.dart`, 이 단계에서는 `MaterialApp(home: Scaffold(body: Text('지출 위젯')))`)

- [ ] **Step 1:** `cd apps && flutter create --org com.spiralmomentum --project-name spend_ledger --platforms ios,android spend_ledger`
- [ ] **Step 2:** iOS `PRODUCT_BUNDLE_IDENTIFIER`를 `com.spiralmomentum.spendLedger`(RunnerTests는 `.RunnerTests`)로, `IPHONEOS_DEPLOYMENT_TARGET = 17.0`, Podfile `platform :ios, '17.0'`, Info.plist `CFBundleDisplayName` = `지출 위젯`. Android `minSdk = 26`, manifest `android:label="지출 위젯"`, `POST_NOTIFICATIONS` 권한
- [ ] **Step 3:** pubspec 의존성: flutter_localizations, flutter_bloc, get_it, equatable, intl ^0.20.2, sqflite_sqlcipher, sqflite_common, flutter_secure_storage, flutter_local_notifications. dev: flutter_lints, mocktail, bloc_test, sqflite_common_ffi. analysis_options는 `apps/life_balance`(브랜치 `feat/life-balance`)와 같은 `include: package:flutter_lints/flutter.yaml`
- [ ] **Step 4:** smoke 테스트 `renders app title`: `pumpWidget(const SpendLedgerApp())` 후 `find.text('지출 위젯')` 1개. `flutter test` PASS
- [ ] **Step 5:** `flutter analyze` 0 issues, `flutter build apk --debug` 성공, `flutter build ios --no-codesign --debug` 성공
- [ ] **Step 6:** Commit `feat(spend_ledger): 앱 생성과 빌드 설정`

### Task 2: 원문 모델과 사용자 필터 (FR-10, 11, 12)

**Files:**
- Create: `lib/features/message_filter/domain/{raw_message.dart, filter_rule.dart, name_registry.dart, filter.dart}`, `test/fixtures/messages.dart`
- Test: `test/features/message_filter/filter_test.dart`

**Interfaces:**
- Produces:
  - `enum MessageSource { iosShortcut, androidSms, androidApp, share, manual }`
  - `class RawMessage { String text; String? sender; DateTime receivedAt; MessageSource source; }` (const, Equatable)
  - `class FilterRule { String? senderPattern; List<String> includeKeywords; List<String> excludeKeywords; }` + `toJson()/fromJson(Map)`
  - `const List<FilterRule> defaultFilterRules` = 규칙 1개: sender 없음, include `['승인','결제','출금','이체','송금','취소','환불']`, exclude `['결제예정','광고','인증번호','입금']` (Ruling R3: '누적' 제거)
  - `class NameRegistry { List<String> selfNames; List<String> chargeTargets; List<String> prepaidMoneys; }` + `toJson/fromJson`, `const NameRegistry.empty()`
  - `bool passesFilter(RawMessage m, List<FilterRule> rules)`
  - `test/fixtures/messages.dart`: 아래 픽스처 상수 (이후 모든 테스트가 사용)

```dart
const kbApproval = '[Web발신]\nKB국민카드1*3*승인\n홍*동님\n6,500원 일시불\n11/27 14:03\n스타벅스\n누적1,234,560원';
const shinhanApproval = '[Web발신]\n신한카드(1234)승인 홍*동 12,000원(일시불)11/27 12:30 김밥천국 누적123,456원';
const kbCancel = '[Web발신]\nKB국민카드1*3*승인취소\n홍*동님\n6,500원 일시불\n11/27 15:10\n스타벅스';
const chargeWithdrawal = '[Web발신]\n[KB]11/27 09:00\n123456**789\n쿠팡페이\n출금100,000\n잔액1,234,000';
const coupayMoneyPayment = '[쿠팡] 쿠페이머니 결제 30,000원\n11/27 18:20 쿠팡';
const friendTransfer = '[Web발신]\n[토스뱅크] 김철수님에게 30,000원 송금 완료';
const selfTransfer = '[Web발신]\n[KB]11/27 10:00\n123456**789\n홍길동\n출금500,000\n잔액734,000';
const cardBillWithdrawal = '[Web발신]\n[KB]11/25 08:00\n123456**789\n신한카드\n출금420,000\n잔액1,334,000';
const noKeyword = '[Web발신]\n현대카드 홍*동 8,900원 11/27 19:40 배달의민족';
const noAmount = '[Web발신]\n삼성카드 승인 안내: 해외 가맹점 이용';
const deposit = '[KB]11/27 입금 50,000 홍길동';
const ad = '(광고) 신한카드 결제 이벤트 안내';
const balanceFirst = '[Web발신]\n하나카드 잔액 80,000원 사용 12,300원 11/27 08:10 GS25';
```

규칙 의미: sender가 `senderPattern`을 포함하거나 pattern이 null이면 그 규칙이 적용된다. 적용 규칙 중 하나라도 exclude 키워드가 본문에 있으면 false. 그다음 본문에 `\d[\d,]*\s*원` 금액 패턴이 있으면 true(검증 기준 5: 키워드 없는 새 형식). 적용 규칙 중 include 키워드를 가진 규칙이 있으면 그 키워드 중 하나 이상이 본문에 있어야 true. 적용 규칙이 없으면 true.

- [ ] **Step 1: 실패 테스트 작성** — `default rules pass approval` (kbApproval → true), `default rules drop deposit` (deposit → false), `default rules drop ad` (ad → false), `amount without keyword passes` (noKeyword → true), `keyword without amount passes` (noAmount → true), `sender-scoped exclude applies only to that sender` (rule sender '1588', exclude '포인트': sender '15881688'+'포인트' 포함 문자 → false, sender '0000' → true), `json roundtrip` (FilterRule, NameRegistry)
- [ ] **Step 2:** `flutter test test/features/message_filter` → FAIL (정의 없음)
- [ ] **Step 3:** 위 Produces 구현
- [ ] **Step 4:** 테스트 PASS
- [ ] **Step 5:** Commit `feat(spend_ledger): 원문 모델과 사용자 필터`

### Task 3: 범용 파서와 형식 서명 (FR-20, 21)

**Files:**
- Create: `lib/features/parsing/domain/{parsed_message.dart, parser.dart, signature.dart}`
- Test: `test/features/parsing/parser_test.dart`, `test/features/parsing/signature_test.dart`

**Interfaces:**
- Consumes: 픽스처(Task 2)
- Produces:
  - `enum MessageKind { approval, withdrawal, transfer, cancel, refund, unknown }`
  - `class ParsedMessage { int? amount; String counterparty; DateTime occurredAt; MessageKind kind; String signature; }` (Equatable, counterparty 못 찾으면 `''`)
  - `ParsedMessage parseMessage(String text, {required DateTime receivedAt, String? sender, FormatHint? hint})` (FormatHint는 Task 4. 이 Task에서는 `hint` 파라미터를 받되 null만 처리)
  - `String formatSignature(String text, String? sender)`
  - `List<String> contentLines(String text)` — trim 후 빈 줄 제외, `[Web발신]` 줄 제외. Task 4가 줄 번호에 사용

규칙(값 고정):
- 금액: `(\d{1,3}(?:,\d{3})+|\d+)\s*원` 매칭 중 매치 시작 직전 8자 안에 `잔액|누적|한도|잔고`가 있는 것 제외, 첫 번째. 없으면 `(출금|이체|송금|결제|승인)\s*(\d{1,3}(?:,\d{3})+|\d+)`의 숫자
- 종류 우선순위: `취소`→cancel, `환불`→refund, `출금|자동이체`→withdrawal, `송금|이체|보냄`→transfer, `승인|결제|사용`→approval, 금액 있음→approval, 그 외 unknown
- 일시: `(\d{1,2})[/.](\d{1,2})\s*(\d{1,2}):(\d{2})` 또는 `(\d{1,2})월\s*(\d{1,2})일`(시각은 receivedAt의 시각). 연도는 receivedAt의 연도, 결과가 receivedAt보다 1일 넘게 미래면 전년. 없으면 receivedAt
- 상대: 다음을 구분자로 치환한 뒤 줄·구분자로 나눈 조각(trim, 길이 2 이상) 중 마지막 — `[...]`·`(...)` 괄호 토큰, 금액 매치와 그 바로 뒤 `일시불|할부\S*`, 잔액/누적+숫자, 일시 매치, `*` 포함 토큰, 종류 키워드와 `완료|안내`, 숫자만 있는 토큰. 종류가 approval·cancel·refund일 때만 `\S*(카드|은행)\S*` 토큰도 제거. 결과 끝의 `님에게|님|에게` 제거
- 서명: `formatSignature`는 `sender ?? ''` + `|` + `contentLines`의 각 줄을 형태 코드로 바꿔 `/`로 이은 값. 형태 코드: 금액 포함 `A`, 일시 포함 `D`, 종류 키워드 포함 시 그 키워드, 둘 이상이면 이어붙임(예 `AD`), 해당 없으면 `T`

- [ ] **Step 1: 실패 테스트 작성** (receivedAt = `DateTime(2026,11,27,20,0)`)

| 테스트 | 입력 | amount | kind | counterparty | occurredAt |
|---|---|---|---|---|---|
| `kb approval` | kbApproval | 6500 | approval | 스타벅스 | 2026-11-27 14:03 |
| `shinhan single line` | shinhanApproval | 12000 | approval | 김밥천국 | 2026-11-27 12:30 |
| `kb cancel` | kbCancel | 6500 | cancel | 스타벅스 | 2026-11-27 15:10 |
| `bank withdrawal without 원` | chargeWithdrawal | 100000 | withdrawal | 쿠팡페이 | 2026-11-27 09:00 |
| `prepaid money payment` | coupayMoneyPayment | 30000 | approval | 쿠팡 | 2026-11-27 18:20 |
| `transfer recipient` | friendTransfer | 30000 | transfer | 김철수 | receivedAt |
| `card bill keeps card name` | cardBillWithdrawal | 420000 | withdrawal | 신한카드 | 2026-11-25 08:00 |
| `no keyword falls back to approval` | noKeyword | 8900 | approval | 배달의민족 | 2026-11-27 19:40 |
| `no amount` | noAmount | null | approval | (검사 안 함) | receivedAt |
| `skips balance before amount` | balanceFirst | 12300 | approval | GS25 | 2026-11-27 08:10 |
| `year rollover` | `'[Web발신]\n신한카드 승인 5,000원 12/31 23:50 편의점'`, receivedAt `2027-01-01 00:05` | 5000 | approval | 편의점 | 2026-12-31 23:50 |

서명 테스트: `same format same signature` — kbApproval과 가맹점·금액·시각만 바꾼 `'[Web발신]\nKB국민카드1*3*승인\n홍*동님\n12,000원 일시불\n11/28 09:00\n이마트\n누적1,246,560원'`의 서명이 같다. `different sender different signature`.
- [ ] **Step 2:** `flutter test test/features/parsing` → FAIL
- [ ] **Step 3:** Produces 구현 (정규식은 위 값 고정, 그 외 세부는 재량)
- [ ] **Step 4:** PASS
- [ ] **Step 5:** Commit `feat(spend_ledger): 범용 결제 문자 파서`

### Task 4: 형식 학습 (FR-22)

**Files:**
- Create: `lib/features/parsing/domain/format_hint.dart`
- Modify: `lib/features/parsing/domain/parser.dart` (hint 적용)
- Test: `test/features/parsing/format_hint_test.dart`

**Interfaces:**
- Consumes: `contentLines`, `formatSignature`, `parseMessage` (Task 3)
- Produces:
  - `class FormatHint { String signature; int? amountOrdinal; int? counterpartyLine; }` + `toJson/fromJson`
  - `FormatHint? learnHint(String text, String? sender, {required int amount, required String counterparty})` — `amountOrdinal`: 원 금액 매치 중 값이 amount인 것의 순번(0부터, 잔액 제외 규칙 없이 전체 매치 기준), `counterpartyLine`: counterparty를 포함하는 `contentLines` 인덱스. 둘 다 못 찾으면 null
  - `parseMessage(..., hint:)`: hint가 있고 `hint.signature == formatSignature(text, sender)`일 때 amountOrdinal 번째 매치를 금액으로, counterpartyLine 줄에서 Task 3의 상대 정리 규칙을 적용한 값을 상대로 쓴다. 줄이 없으면 기본 규칙

- [ ] **Step 1: 실패 테스트** — `learned counterparty applies to next message of same format`: A = `'[Web발신]\n우리카드 승인\n홍*동\n맛있는분식 본점\n7,000원\n본사 고객센터 문의\n누적 90,000원'` (기본 규칙은 마지막 조각 `본사 고객센터 문의`를 상대로 읽는다 — 이 값을 assert해 학습 전 오답을 고정). `learnHint(A, null, amount: 7000, counterparty: '맛있는분식 본점')` → counterpartyLine 2. B = A에서 가맹점만 `행복마트 역삼점`, 금액 `3,000원`, 누적 `93,000원`으로 바꾼 문자를 hint로 파싱 → counterparty `행복마트 역삼점`, amount 3000. `learned ordinal picks second amount`: `'[Web발신]\n신한 체크 잔액 5,000원\n승인 2,500원 카페'`에서 학습 amount 2500 → ordinal 1, 같은 형식 다른 값에서 두 번째 금액 사용. `hint ignored for other signature`. `returns null when amount absent`
- [ ] **Step 2:** FAIL 확인
- [ ] **Step 3:** 구현
- [ ] **Step 4:** `flutter test test/features/parsing` 전체 PASS
- [ ] **Step 5:** Commit `feat(spend_ledger): 파싱 형식 학습`

### Task 5: 거래 모델과 분류·중복·취소 매칭 (FR-32, 33, 40~45)

**Files:**
- Create: `lib/features/ledger/domain/{transaction.dart, merchant_match.dart, decide.dart}`
- Test: `test/features/ledger/decide_test.dart`

**Interfaces:**
- Consumes: `RawMessage`, `NameRegistry` (Task 2), `ParsedMessage`, `MessageKind` (Task 3)
- Produces:
  - `enum SpendCategory { spend, prepaidCharge, transferOut, internal, prepaidUse, refund, unknown }`
  - `enum TxStatus { pending, included, excluded, duplicate, cancelled }`
  - `class Transaction { String id; int amount; String counterparty; DateTime occurredAt; DateTime receivedAt; MessageKind kind; SpendCategory category; TxStatus status; String? linkedId; String? rawText; String? sender; bool needsReview; String signature; }` + `copyWith`, Equatable
  - `bool merchantMatches(String a, String b)` — 공백 제거·소문자 후 둘 다 비어 있지 않고 한쪽이 다른 쪽을 포함
  - `class LedgerDecision { Transaction incoming; List<Transaction> updated; bool notify; }`
  - `LedgerDecision decide({required RawMessage raw, required ParsedMessage parsed, required NameRegistry names, required List<Transaction> recent, required String newId})`

판정 순서(값 고정):
1. amount null → category unknown, status pending, needsReview true, notify false
2. kind cancel/refund → 원거래 탐색: recent 중 `amount == parsed.amount`, `merchantMatches`, `occurredAt <= parsed.occurredAt`, 그리고 (status in {included, pending} 또는 category == prepaidUse) 인 것 중 occurredAt 가장 늦은 1건.
   - 찾음 → 원거래 status cancelled를 updated에 넣고, incoming은 category refund, amount `-parsed.amount`, status excluded, linkedId 원거래 id, notify false
   - 못 찾음 + 본문에 prepaidMoneys 이름 포함 → incoming refund, 음수, excluded, notify false
   - 못 찾음 → incoming refund, 음수, pending, notify true
3. 중복: recent 중 `|receivedAt 차이| <= 5분`, 같은 amount, `merchantMatches`, status != duplicate 인 것 있으면 → 분류는 4와 같이 하되 status duplicate, notify false
4. approval: 본문에 prepaidMoneys 포함 → prepaidUse excluded notify false; 아니면 spend pending notify true
5. withdrawal/transfer: 본문에 chargeTargets 포함 → prepaidCharge pending notify true; 아니면 본문에 selfNames 포함 → internal excluded notify false; 아니면 transferOut pending notify true

incoming은 `rawText = raw.text`, `sender = raw.sender`, `receivedAt = raw.receivedAt`.

- [ ] **Step 1: 실패 테스트** (names: selfNames `['홍길동','신한카드']`, chargeTargets `['쿠팡페이']`, prepaidMoneys `['쿠페이머니']`; 파싱은 `parseMessage` 실제 사용)
  - `card approval is pending spend with notify`
  - `charge withdrawal is prepaidCharge pending` (chargeWithdrawal)
  - `prepaid money payment auto excluded` (coupayMoneyPayment → prepaidUse, excluded, notify false)
  - `friend transfer is transferOut` / `self transfer internal excluded` / `card bill internal excluded`
  - `cancel matches included original` (recent에 kbApproval 기반 included 거래 → updated[0].status cancelled, incoming.amount -6500, linkedId)
  - `cancel matches prepaidUse without effect` / `cancel without original becomes negative pending`
  - `duplicate within 5 minutes` (같은 kbApproval을 receivedAt +3분 → duplicate, notify false) / `same message after 6 minutes is not duplicate`
  - `no amount needs review`
- [ ] **Step 2:** FAIL
- [ ] **Step 3:** 구현
- [ ] **Step 4:** PASS
- [ ] **Step 5:** Commit `feat(spend_ledger): 지출 분류와 중복·취소 매칭`

### Task 6: 기간·요약·예산 알림·위젯 페이로드 (FR-51~55, 60, 61, NFR-03)

**Files:**
- Create: `lib/features/budget/domain/{period.dart, summary.dart, budget_alert.dart}`, `lib/features/ledger/domain/money_format.dart`, `lib/features/widget_sync/domain/widget_entries.dart`
- Test: `test/features/budget/{period_test.dart, summary_test.dart, budget_alert_test.dart}`, `test/features/widget_sync/widget_entries_test.dart`

**Interfaces:**
- Consumes: `Transaction`, `TxStatus` (Task 5)
- Produces:
  - `class BudgetPeriod { DateTime start; DateTime endExclusive; int get totalDays; String get key; }` (key = `yyyy-MM-dd` of start)
  - `BudgetPeriod periodFor(DateTime date, int startDay)` — startDay 1~31, 그 달에 없으면 말일
  - `String formatWon(int amount)` → `6,500원`, 음수 `-6,500원`
  - `class MerchantTotal { String name; int amount; }`
  - `class LedgerSummary { BudgetPeriod period; int periodTotal; int todayTotal; int? budget; double? budgetRatio; int? dailyAllowance; int elapsedDays; double elapsedRatio; List<MerchantTotal> topMerchants; List<Transaction> recent; int pendingCount; }`
  - `LedgerSummary summarize({required List<Transaction> txs, required DateTime now, required int startDay, int? budget})` — 합계는 status included이고 occurredAt이 기간 안인 거래의 amount 합. elapsedDays는 오늘 포함. dailyAllowance = `max(0, budget - periodTotal) ~/ (totalDays - elapsedDays + 1)`. topMerchants: 기간 included 거래를 counterparty별 합산, 양수만, 상위 3. recent: 기간 included 최신 3건. pendingCount: 전체 pending 수
  - `enum BudgetAlert { projectedOver, actualOver }`
  - `BudgetAlert? nextBudgetAlert(LedgerSummary s, Set<BudgetAlert> sent)` — budget null이면 null. periodTotal > budget이고 actualOver 미발송 → actualOver. 아니면 `periodTotal / elapsedDays * totalDays > budget`이고 projectedOver 미발송 → projectedOver
  - `Map<String, String> widgetEntries(LedgerSummary s, {required bool hideAmounts})` — 키: `total, ratio, today, daily, elapsed, top1..top3, recent1..recent3, pending`. 금액은 `formatWon`, ratio·elapsed는 정수 퍼센트 문자열 `"42"`, top/recent는 `"{이름} {금액}"`. hideAmounts면 total/today/daily와 top·recent 값의 금액 부분을 빈 문자열로, ratio·elapsed·pending은 유지

- [ ] **Step 1: 실패 테스트** — `period start day 25` (2026-11-27, 25 → 11-25 ~ 12-25), `period before start day` (2026-11-10, 25 → 10-25 ~ 11-25), `start day 31 in february` (2027-02-15, 31 → 2027-01-31 ~ 2027-02-28), `summary counts only included in period`, `daily allowance` (예산 300000, 합계 120000, 11/1~12/1 기간 11/27 → 남은 4일 → 45000), `top merchants sorted`, `pending count`, `actual over then projected`(각 1회), `widget hides amounts keeps ratio`, `widget total equals summary total`
- [ ] **Step 2:** FAIL
- [ ] **Step 3:** 구현
- [ ] **Step 4:** PASS
- [ ] **Step 5:** Commit `feat(spend_ledger): 기간 요약과 예산 알림 판정`

### Task 7: 암호화 저장소 (NFR-01)

**Files:**
- Create: `lib/features/ledger/data/{ledger_database.dart, sql_ledger_repository.dart, db_key.dart}`, `lib/features/parsing/data/sql_format_hint_repository.dart`, `lib/features/settings/domain/app_settings.dart`, `lib/features/settings/data/sql_settings_repository.dart`, `test/support/memory_db.dart`
- Test: `test/features/ledger/data/sql_ledger_repository_test.dart`, `test/features/settings/sql_settings_repository_test.dart`, `test/features/ledger/data/db_key_test.dart`

**Interfaces:**
- Consumes: `Transaction` (Task 5), `FormatHint` (Task 4), `FilterRule`, `NameRegistry`, `defaultFilterRules` (Task 2), `BudgetAlert` (Task 6)
- Produces:
  - `Future<void> createLedgerSchema(Database db)` — 테이블 `transactions`(Transaction 전 필드), `format_hints(signature PK, json)`, `kv(key PK, value)`. DB 버전 1. `Database`는 `package:sqflite_common/sqlite_api.dart`
  - `Future<Database> openLedgerDatabase(String path, String key)` — sqflite_sqlcipher `openDatabase(path, password: key, version: 1, onCreate: ...)`
  - `abstract interface class KeyStore { Future<String?> read(); Future<void> write(String v); }`, `SecureKeyStore`(flutter_secure_storage, iOS `first_unlock`)
  - `Future<String> loadOrCreateDbKey(KeyStore store, Random random)` — 32바이트 → base64
  - `abstract interface class LedgerRepository { Future<void> upsertAll(List<Transaction> txs); Future<Transaction?> byId(String id); Future<List<Transaction>> since(DateTime from); Future<List<Transaction>> byStatus(Set<TxStatus> statuses); }`, `SqlLedgerRepository(Database)`
  - `abstract interface class FormatHintRepository { Future<FormatHint?> get(String signature); Future<void> put(FormatHint hint); }`, `SqlFormatHintRepository(Database)`
  - `class AppSettings { int startDay = 1; int? budget; bool deleteRawText = true; bool hideAmounts = false; List<FilterRule> filters = defaultFilterRules; NameRegistry names = NameRegistry.empty(); }` + copyWith/toJson/fromJson
  - `abstract interface class SettingsRepository { Future<AppSettings> load(); Future<void> save(AppSettings s); Future<Set<BudgetAlert>> sentAlerts(String periodKey); Future<void> markSent(String periodKey, BudgetAlert a); }`, `SqlSettingsRepository(Database)` (kv 테이블)
  - `test/support/memory_db.dart`: `Future<Database> openMemoryDb()` — `sqfliteFfiInit()`, `databaseFactoryFfi.openDatabase(inMemoryDatabasePath, options: OpenDatabaseOptions(version: 1, onCreate: (db, _) => createLedgerSchema(db)))`

- [ ] **Step 1: 실패 테스트** — `upsert then byId roundtrip`(모든 필드), `upsert replaces same id`, `since filters by occurredAt`, `byStatus`, `settings default when empty`, `settings roundtrip`, `sent alerts per period`, `hint roundtrip`, `key created once and reused`(fake KeyStore, 두 번 호출 같은 값, 디코드 길이 32)
- [ ] **Step 2:** FAIL
- [ ] **Step 3:** 구현
- [ ] **Step 4:** PASS
- [ ] **Step 5:** Commit `feat(spend_ledger): 암호화 저장소`

### Task 8: 수집 유스케이스와 확인 알림, 검증 기준 테스트 (FR-30~33, NFR-02, 원본 6절)

**Files:**
- Create: `lib/features/ingest/domain/ingest.dart`, `lib/features/confirm_notification/domain/notification_text.dart`, `lib/features/confirm_notification/data/local_confirm_notifier.dart`, `test/support/fakes.dart`
- Test: `test/features/ingest/ingest_test.dart`, `test/acceptance/acceptance_test.dart`, `test/features/confirm_notification/notification_text_test.dart`

**Interfaces:**
- Consumes: Task 2~7 전체
- Produces:
  - `abstract interface class ConfirmNotifier { Future<void> askConfirm(Transaction tx); Future<void> budgetAlert(BudgetAlert alert, LedgerSummary s); Future<void> cancel(String txId); }`
  - `abstract interface class WidgetGateway { Future<void> save(Map<String, String> entries); }`, `NoopWidgetGateway`
  - `class IngestDeps { LedgerRepository ledger; SettingsRepository settings; FormatHintRepository hints; ConfirmNotifier notifier; WidgetGateway widgets; DateTime Function() now; String Function() newId; }`
  - `enum IngestResult { filtered, stored }`
  - `Future<(IngestResult, Transaction?)> ingestMessage(RawMessage raw, IngestDeps d)` — settings.load → passesFilter(false면 filtered) → hints.get(signature) → parseMessage → ledger.since(now - 90일) → decide → upsertAll([incoming, ...updated]) → notify면 askConfirm → refreshOutputs
  - `Future<void> resolveCandidate(String id, bool include, IngestDeps d)` — 대상 status가 pending일 때만 included/excluded로 바꿈(그 외 무시). deleteRawText면 rawText null. notifier.cancel(id) → refreshOutputs
  - `Future<void> saveEdit(Transaction edited, IngestDeps d)` — rawText가 있으면 `learnHint` 후 hints.put. upsert → refreshOutputs
  - `Future<LedgerSummary> refreshOutputs(IngestDeps d)` — txs = `ledger.since(periodFor(now, startDay).start)` ∪ `ledger.byStatus({pending})`(id 기준 합집합) → summarize → widgets.save(widgetEntries(hideAmounts)) → nextBudgetAlert(sentAlerts(period.key))가 있으면 notifier.budgetAlert + markSent
  - `String confirmBody(Transaction tx)` — Global Constraints 문구 두 가지
  - `LocalConfirmNotifier(FlutterLocalNotificationsPlugin)`: 카테고리/채널 id `confirm`, 액션 id `include`/`exclude`(둘 다 앱을 열지 않음: Android `showsUserInterface: false`, iOS `DarwinNotificationActionOption` 없이), payload = tx.id, 알림 id = `tx.id.hashCode`. 예산 알림 채널 `budget`, 문구 actualOver `이번 달 예산 {예산}을 넘었어요.`, projectedOver `이대로면 이번 달 예산을 넘을 것 같아요.`
  - `Future<void> initNotifications(FlutterLocalNotificationsPlugin p, {required void Function(NotificationResponse) onForeground, required void Function(NotificationResponse) onBackground})` — 카테고리·채널 등록 후 `initialize`에 두 핸들러 전달. onBackground 실제 함수는 Task 11의 `notificationBackgroundHandler`(최상위 함수)이고, Task 9까지는 bootstrap이 그 자리에 같은 시그니처의 최상위 함수를 넘긴다
- `test/support/fakes.dart`: `FakeNotifier`(asked/alerts 기록), `MemoryWidgetGateway`(마지막 entries 보관), `IngestDeps` 생성 헬퍼(메모리 DB 사용)

- [ ] **Step 1: 실패 테스트 — 검증 기준 5개** (`test/acceptance/acceptance_test.dart`, names는 Task 5와 동일, startDay 1)
  1. `charge then money payment counts once`: chargeWithdrawal ingest → resolve include → coupayMoneyPayment ingest → 요약 periodTotal 100000, 두 번째 ingest는 askConfirm 없음
  2. `friend transfer counts, self and card bill do not`: 세 문자 ingest, 송금만 asked → resolve include → total 30000
  3. `cancel removes original`: kbApproval ingest·include(total 6500) → kbCancel ingest → total 0
  4. `unanswered stays out of total`: kbApproval ingest만 → total 0, byStatus(pending) 1건, widget entries `pending` == `"1"`
  5. `new format without 승인 notifies`: noKeyword ingest → asked 1건, body에 `배달의민족에서 8,900원`
- [ ] **Step 2: 실패 테스트 — 유스케이스** `deposit filtered not stored`, `no amount stored as needs review without notify`, `resolve ignores cancelled`(cancelled 거래에 include → 그대로 cancelled), `resolve deletes raw text when enabled`, `edit learns hint`(saveEdit 후 hints.get(signature) not null), `budget alert sent once`
- [ ] **Step 3:** `flutter test test/acceptance test/features/ingest` → FAIL
- [ ] **Step 4:** 구현
- [ ] **Step 5:** PASS, 전체 `flutter test` PASS
- [ ] **Step 6:** Commit `feat(spend_ledger): 수집 유스케이스와 확인 알림`

### Task 9: 앱 화면 — 홈, 후보 리스트, 수정 (FR-31, 32, 33)

**Files:**
- Create: `lib/app/{bootstrap.dart, di/service_locator.dart}`, `lib/features/budget/presentation/{home_page.dart, home_cubit.dart}`, `lib/features/ledger/presentation/{candidates_page.dart, candidates_cubit.dart, edit_page.dart, edit_cubit.dart}`
- Modify: `lib/main.dart`, `lib/app/spend_ledger_app.dart`
- Test: `test/features/budget/home_cubit_test.dart`, `test/features/ledger/candidates_cubit_test.dart`, `test/features/ledger/edit_cubit_test.dart`, `test/app/spend_ledger_app_test.dart`

**Interfaces:**
- Consumes: `IngestDeps`, `refreshOutputs`, `resolveCandidate`, `saveEdit`, `ingestMessage` (Task 8)
- Produces:
  - `Future<IngestDeps> buildIngestDeps()` (`lib/app/bootstrap.dart`) — 키 로드, DB 열기(`getDatabasesPath()/ledger.db`), 알림 초기화, 리포지토리 조립. 메인 앱과 헤드리스 엔진·백그라운드 핸들러가 같이 사용
  - `HomeCubit(IngestDeps)` 상태 `HomeState { LedgerSummary? summary; bool loading; }`, `load()`
  - `CandidatesCubit(IngestDeps)` 상태 3목록: `waiting`(pending && !needsReview), `needsReview`(pending && needsReview), `auto`(최근 90일 excluded 중 internal/prepaidUse + duplicate). `include(id)`, `exclude(id)`, `load()`
  - `EditCubit(IngestDeps, Transaction)`: `save({int amount, String counterparty, DateTime occurredAt, SpendCategory category, bool include})` → saveEdit 후 include면 status included
  - `GlobalKey<NavigatorState> appNavigatorKey`, 라우트: `/` 홈, `/candidates`, `/edit?id=`, `/settings`
  - 알림 본문 탭(onForeground, 액션 id 없음) → `/edit?id=payload`. 앱이 알림으로 실행된 경우 `getNotificationAppLaunchDetails`로 같은 처리
- 홈 화면 구성: 이번 달 합계(큰 숫자), 예산 비율, 오늘 지출, 하루 권장액, 경과 대비 진행 막대, 대기 후보 배지(탭 → 후보 리스트), 최근 거래 3건. 수동 입력 버튼(문자 붙여넣기 → `ingestMessage(source: manual)`)

- [ ] **Step 1: 실패 테스트** — `home loads summary`, `candidates split into three lists`, `include moves item out of waiting`, `edit save includes and learns`, `app shows home total`(위젯 테스트, 메모리 DB deps 주입)
- [ ] **Step 2:** FAIL
- [ ] **Step 3:** 구현 (화면 디자인 재량, 숫자는 `FontFeature.tabularFigures()`)
- [ ] **Step 4:** PASS, `flutter analyze` 0 issues
- [ ] **Step 5:** Commit `feat(spend_ledger): 홈·후보 리스트·수정 화면`

### Task 10: 설정 화면 — 기간·예산·필터·이름·파싱 테스트·단축어 안내 (FR-02, 10~12, 23, 55, 60, 61, NFR-01)

**Files:**
- Create: `lib/features/settings/presentation/{settings_page.dart, settings_cubit.dart, filters_page.dart, names_page.dart}`, `lib/features/parsing/presentation/parse_test_page.dart`, `lib/features/ingest/presentation/shortcut_guide_page.dart`
- Test: `test/features/settings/settings_cubit_test.dart`, `test/features/parsing/parse_test_page_test.dart`

**Interfaces:**
- Consumes: `SettingsRepository`, `AppSettings` (Task 7), `parseMessage`, `decide` (Task 3, 5), `refreshOutputs` (Task 8)
- Produces:
  - `SettingsCubit(SettingsRepository, Future<void> Function() refresh)`: `setStartDay(int)`(1~31 범위 밖 무시), `setBudget(int?)`, `setDeleteRawText(bool)`, `setHideAmounts(bool)`, `saveFilters(List<FilterRule>)`, `saveNames(NameRegistry)` — 저장 후 refresh 호출
  - 파싱 테스트 화면: 텍스트 입력 → 저장 없이 필터 통과 여부, 금액, 종류, 상대, 일시, 분류(category), 알림 여부를 표시. `decide`에 `recent: []` 전달
  - 단축어 안내 화면 문구(단계): 1) 단축어 앱 → 자동화 → 새로운 자동화 → 메시지 2) 메시지 내용에 `원` 포함, '즉시 실행' 선택, '실행 시 알림' 끔 3) 동작에 '결제 문자 기록'(지출 위젯) 추가, 메시지 = 단축어 입력 4) 저장. 설치 링크는 3단계 범위(자리만 두지 않음)
- [ ] **Step 1: 실패 테스트** — `start day out of range ignored`, `saving names triggers refresh`, `parse test page shows amount and category`(kbApproval 붙여넣기 → `6,500원`, `지출` 표시)
- [ ] **Step 2:** FAIL
- [ ] **Step 3:** 구현 (category 표시명: spend 지출, prepaidCharge 선불 충전, transferOut 송금, internal 내부이체, prepaidUse 선불 머니 사용, refund 환불, unknown 확인 필요)
- [ ] **Step 4:** PASS
- [ ] **Step 5:** Commit `feat(spend_ledger): 설정·파싱 테스트·단축어 안내 화면`

### Task 11: iOS 수집 프로토타입 (설계 7절)

**Files:**
- Create: `lib/app/ingest_entry.dart`, `lib/features/ingest/presentation/diagnostics_page.dart`, `ios/Runner/RecordPaymentMessageIntent.swift`, `ios/Runner/HeadlessIngest.swift`, `ios/Runner/IngestDiagnostics.swift`
- Modify: `ios/Runner/AppDelegate.swift`, `ios/Runner.xcodeproj/project.pbxproj` (새 Swift 파일 Runner 타깃 등록)
- Test: `test/app/ingest_entry_test.dart`

**Interfaces:**
- Consumes: `buildIngestDeps` (Task 9), `ingestMessage`, `resolveCandidate` (Task 8)
- Produces:
  - Dart `@pragma('vm:entry-point') Future<void> iosIngestMain()` — `WidgetsFlutterBinding.ensureInitialized()`, deps 생성, MethodChannel `spend_ledger/ingest` 핸들러 등록 후 `ready` 호출로 Swift에 준비 신호
  - Dart `Future<Map<String, Object?>> handleIngestCall(MethodCall call, IngestDeps deps)` — method `ingest`, args `{text, sender?}` → `ingestMessage(RawMessage(source: iosShortcut, receivedAt: now))` → `{result: 'filtered'|'stored', txId?, notified: bool, dartMs: int}`
  - Dart `@pragma('vm:entry-point') void notificationBackgroundHandler(NotificationResponse r)` — actionId `include`/`exclude`면 deps 생성 후 `resolveCandidate`
  - Swift `struct RecordPaymentMessageIntent: AppIntent` — title `결제 문자 기록`, `@Parameter text: String`, `@Parameter sender: String?`, `static var openAppWhenRun = false`, `perform()`가 `HeadlessIngest.shared.ingest(text:sender:)`를 await하고 `.result()` 반환. `AppShortcutsProvider`에 등록(문구 `\(.applicationName)에 결제 문자 기록`)
  - Swift `HeadlessIngest`: 엔진이 없으면 `FlutterEngine(name: "ingest", project: nil, allowHeadlessExecution: true)` 생성, `run(withEntrypoint: "iosIngestMain")`, `GeneratedPluginRegistrant.register(with:)`, `ready` 신호 대기(최대 10초) 후 `ingest` 호출(최대 15초). 단계별 시각(시작, 엔진 준비, Dart 응답)을 `IngestDiagnostics`에 기록. 실패·타임아웃 시 대체안: 원문을 `UserDefaults` 키 `pending_inbox`(문자열 배열)에 추가하고, 정규식 `(\d{1,3}(,\d{3})+|\d+)\s*원`으로 금액만 읽어 `UNUserNotificationCenter`로 `{금액}원 결제 문자가 왔어요. 앱에서 확인해 주세요.` 알림
  - Swift `IngestDiagnostics`: 최근 20건 `{at, path(headless|fallback), engineMs, dartMs, totalMs, result}`을 UserDefaults `ingest_diagnostics`에 JSON 배열로 저장. MethodChannel `spend_ledger/diagnostics`의 `list`, `drainInbox`로 Dart에 제공
  - 앱 시작 시(`bootstrap`) `drainInbox` 결과를 `ingestMessage(source: iosShortcut)`로 처리
  - 진단 화면: 최근 기록 목록과 각 ms, 설정 화면에서 진입

- [ ] **Step 1: 실패 테스트** — `handleIngestCall stores and reports notified`(kbApproval → `result == 'stored'`, `notified == true`), `handleIngestCall reports filtered`(deposit)
- [ ] **Step 2:** FAIL → 구현 → PASS
- [ ] **Step 3:** Swift 구현, `flutter build ios --no-codesign --debug` 성공
- [ ] **Step 4:** 실기기 검증 안내를 `apps/spend_ledger/README.md`에 작성 — 설치(`flutter run --release` + Xcode 서명 팀 BXMP99D98Z), 단축어 자동화 생성(Task 10 문구), 확인 항목 4개(설계 7절 질문 1~4)와 진단 화면에서 볼 값: 질문 3 합격 기준 `totalMs <= 3000`(NFR-02)
- [ ] **Step 5:** Commit `feat(spend_ledger): iOS 단축어 수집 프로토타입`
- [ ] **Step 6:** 사용자에게 실기기 검증 요청. 결과(진단 화면 값)를 받아 설계 문서 7절에 기록한다. 이 단계는 사용자 응답 전까지 완료로 표시하지 않는다
