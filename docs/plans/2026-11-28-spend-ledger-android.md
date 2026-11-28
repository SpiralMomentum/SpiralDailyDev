# 지출 위젯 2단계 (Android) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 갤럭시(삼성 메시지)에서 결제 알림을 자동으로 받아 1단계 Dart 처리 흐름으로 저장하고, 홈 화면 위젯 소·중·대로 보여 준다.

**Architecture:** Kotlin `NotificationListenerService`가 허용 앱 알림에서 원문만 뽑아 백그라운드 FlutterEngine(`androidIngestMain`)에 `spend_ledger/ingest` 채널로 넘긴다. Dart는 기존 `ingestMessage`를 그대로 쓰고, 재게시 중복만 해시로 거른다. 위젯은 `home_widget`이 저장한 요약 페이로드를 Kotlin `AppWidgetProvider` 3개가 그린다.

**Tech Stack:** Flutter 3.41.2 / Dart 3.11.0, Kotlin, sqflite_sqlcipher, flutter_local_notifications, home_widget, JUnit 4

**Spec:** `docs/plans/2026-11-27-spend-ledger-design.md` 10절(2단계). 원본 요구사항은 `doc/26_Q4/가계부.md`.

## Global Constraints

- 앱 경로 `apps/spend_ledger`. Android applicationId·Kotlin 패키지 `com.spiralmomentum.spend_ledger`, minSdk 26.
- 코드 생성(build_runner) 금지. 테스트 모킹은 mocktail. 상태 관리는 기존 cubit + `RepositoryProvider<IngestDeps>`.
- `lib/features/*/domain`은 `package:flutter`를 import하지 않는다. 도메인 함수는 순수 함수로 쓴다.
- 채널 이름: `spend_ledger/ingest`(수집), `spend_ledger/diagnostics`(진단 `list`), `spend_ledger/android`(Android 전용 설정).
- 문자 원문은 로그, 진단 기록, 네이티브 저장소(SharedPreferences)에 남기지 않는다(NFR-01). 네이티브에 저장해도 되는 것: 패키지 이름, 진단 수치, 위젯 페이로드.
- 기본 허용 앱: `com.samsung.android.messaging`, `com.google.android.apps.messaging`. 이 둘이 문자 앱(`MessageSource.androidSms`)이고 나머지 허용 앱은 `androidApp`.
- 재게시 중복 창: 10분.
- 외부 네트워크, 분석·크래시 SDK 금지.
- iOS 동작과 코드는 바꾸지 않는다(공유 Dart 코드 수정은 iOS 경로 테스트가 계속 통과해야 함). `flutter build ios --no-codesign`이 계속 성공해야 한다.
- UI 문구는 한국어, 이모지 금지.
- 커밋 메시지 끝: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. 저장소의 관련 없는 미추적 파일(`apps/*/store_listing.json`, `apps/color_snap/`, `apps/life_balance/`, `tools/store/`, `.superpowers/`)은 절대 add하지 않는다.
- 검증 명령(앱 디렉터리에서): `flutter test`, `flutter analyze`, `flutter build apk --debug`. Kotlin 단위 테스트: `cd android && ./gradlew :app:testDebugUnitTest`.

## Review Focus

1. 삼성 메시지가 같은 알림을 갱신하며 다시 올림: 같은 `(패키지, 원문)`은 10분 안에 한 번만 저장되어야 한다 → Task 2 `seen` 테스트, Task 3 마지막 메시지 추출 테스트.
2. 엔진이 뜨는 중에 알림이 연달아 옴: 큐에 쌓였다가 순서대로 모두 넘어가야 하고, 준비 시간 초과면 진단에 남고 서비스가 죽지 않아야 한다 → Task 3 `IngestQueue` 테스트.
3. 처리 중 실패한 알림이 다시 올라옴: 실패한 건은 `seen`에 남지 않아 재게시 때 다시 처리되어야 한다 → Task 2 테스트.
4. 허용 앱을 모두 지움: 아무것도 수집되지 않으므로 화면에 경고가 보여야 한다 → Task 4 테스트.
5. 자정·기간 시작일이 지나도 문자가 안 옴: 날짜 변경 때 `refresh`로 위젯 요약이 다시 계산되어야 한다 → Task 2 `refresh` 테스트, Task 5 `asOf` 테스트.

---

### Task 1: 취소 처리 원자화와 백업 차단

**Files:**
- Modify: `lib/features/ledger/domain/ledger_repository.dart`, `lib/features/ledger/data/sql_ledger_repository.dart`, `lib/features/ingest/domain/ingest.dart`, `lib/app/ingest_entry.dart`(`_UpsertRecorder`), `test/support/fakes.dart`(해당 시)
- Modify: `android/app/src/main/AndroidManifest.xml`
- Create: `android/app/src/main/res/xml/data_extraction_rules.xml`, `android/app/src/main/res/xml/backup_rules.xml`
- Test: `test/features/ledger/data/sql_ledger_repository_test.dart`(기존 파일에 추가), `test/features/ingest/ingest_test.dart`(기존 파일에 추가), `test/android_config_test.dart`

**Interfaces:**
- Produces: `LedgerRepository.saveIncoming(Transaction incoming, List<String> cancelIds, {required bool clearRawText}) -> Future<Set<String>>` — 한 DB 트랜잭션에서 `incoming`을 insert(replace)하고, 각 id에 기존 `markCancelled`와 같은 조건부 UPDATE를 실행한다. 실제로 취소된 id 집합을 돌려준다. 어느 문장이든 실패하면 전체가 롤백되고 예외를 던진다.
- `ingestMessage`는 `upsertAll([incoming])` + `markCancelled` 반복 대신 `saveIncoming` 한 번을 쓴다. 다른 호출자가 없으면 `markCancelled`는 인터페이스에서 지운다.

- [ ] **Step 1: 실패하는 테스트 작성**
  - `saveIncoming stores incoming and cancels matching original in one call`: 포함된 원거래 저장 → `saveIncoming(refund, [orig.id], clearRawText: true)` → 반환값 `{orig.id}`, 원거래 status `cancelled`·rawText null, refund 저장됨.
  - `saveIncoming skips originals no longer cancellable`: 원거래를 `excluded`로 둔 뒤 호출 → 반환 `{}`, 원거래 그대로, refund는 저장.
  - `saveIncoming rolls back incoming when a cancel update fails`: 테스트 DB에 `CREATE TRIGGER fail_cancel BEFORE UPDATE ON transactions WHEN OLD.id = 'orig' BEGIN SELECT RAISE(ABORT, 'boom'); END` → 호출이 예외를 던지고 `byId(refund.id)`가 null.
  - ingest 테스트: 기존 취소 시나리오가 그대로 통과하고, `_UpsertRecorder`가 `saveIncoming` 성공 뒤 incoming id를 기록하는지(저장 뒤 알림 실패 시 `stored`+`notifyError`).
  - `android_config_test.dart`: `AndroidManifest.xml`에 `android:allowBackup="false"`, `android:dataExtractionRules="@xml/data_extraction_rules"`, `android:fullBackupContent="@xml/backup_rules"`가 있고, `data_extraction_rules.xml`의 `<cloud-backup>`과 `<device-transfer>` 모두에 `root`, `file`, `database`, `sharedpref`, `external` 도메인 exclude가 있음.
- [ ] **Step 2: `flutter test test/features/ledger test/features/ingest test/android_config_test.dart` 실행, 새 테스트 FAIL 확인**
- [ ] **Step 3: 구현.** `saveIncoming`은 `_db.transaction((txn) async {...})`. backup_rules.xml은 `<full-backup-content>`에 같은 5개 도메인 exclude.
- [ ] **Step 4: 같은 명령 PASS, 이어서 전체 `flutter test`, `flutter analyze` 0건**
- [ ] **Step 5: 커밋** `fix(spend_ledger): 취소 처리 한 트랜잭션으로 묶고 백업 차단`

### Task 2: Android 수집 Dart 쪽

**Files:**
- Create: `lib/features/ingest/domain/android_sources.dart`, `lib/features/ingest/domain/seen_repository.dart`, `lib/features/ingest/data/sql_seen_repository.dart`, `lib/features/ingest/data/android_bridge.dart`
- Modify: `lib/features/ingest/domain/ingest.dart`(IngestDeps), `lib/app/ingest_entry.dart`, `lib/app/bootstrap.dart`, `lib/features/ledger/data/ledger_database.dart`(스키마 v2), `lib/features/settings/domain/app_settings.dart`, `test/support/memory_db.dart`·`fakes.dart`(필요 시)
- Test: `test/features/ingest/android_sources_test.dart`, `test/features/ingest/sql_seen_repository_test.dart`, `test/app/ingest_entry_test.dart`(기존 파일에 추가), `test/features/settings/sql_settings_repository_test.dart`(기존 파일에 추가), `test/features/ingest/android_bridge_test.dart`

**Interfaces:**
- Produces (domain, `android_sources.dart`):
  - `const List<String> defaultNotificationPackages = ['com.samsung.android.messaging', 'com.google.android.apps.messaging'];`
  - `const Set<String> smsPackages` (같은 두 값)
  - `MessageSource sourceForPackage(String? package)` — null → `iosShortcut`, `smsPackages` → `androidSms`, 그 밖 → `androidApp`
  - `String notificationFingerprint(String package, String text)` — `'$package\n$text'`의 FNV-1a 64비트 16진 문자열(16자리, 0 채움)
- Produces (`seen_repository.dart`): `abstract interface class SeenRepository { Future<bool> claim(String fingerprint, DateTime at, Duration window); Future<void> release(String fingerprint); }` — `claim`은 창 밖의 오래된 기록을 지우고, 같은 지문이 창 안에 없을 때만 기록하며 true. `release`는 기록을 지운다. 기본 구현 `class NoSeenFilter implements SeenRepository`(항상 true, release 무동작).
- `IngestDeps`에 `final SeenRepository seen;` 추가, 생성자 기본값 `const NoSeenFilter()`.
- DB 스키마 v2: `CREATE TABLE seen_notifications(fingerprint TEXT PRIMARY KEY, at INTEGER NOT NULL)`. `openLedgerDatabase`는 `version: 2`, `onUpgrade`에서 v1→v2 생성, `createLedgerSchema`도 새 테이블 포함. `SqlSeenRepository(Database)`는 `INSERT OR IGNORE`로 한 문장 판정.
- `AppSettings.notificationPackages: List<String>` 기본 `defaultNotificationPackages`, JSON 키 `notificationPackages`, `copyWith` 지원, 없는 JSON은 기본값.
- `ingest` 채널 계약 확장: 인자 `{text, sender?, package?, postedAtMs?}`.
  - `receivedAt` = `postedAtMs`가 있으면 그 시각, 없으면 `deps.now()`. `source` = `sourceForPackage(package)`.
  - `package`가 있으면 `seen.claim(notificationFingerprint(package, text), receivedAt, Duration(minutes: 10))`. false면 `{result: 'seen', notified: false, dartMs}`를 돌려주고 저장하지 않는다. 저장 결과가 `error`면 `seen.release`.
  - 새 메서드 `refresh`: `refreshOutputs(deps)` 후 `{result: 'refreshed', dartMs}`. 실패 시 `{result: 'error', error: 타입명, dartMs}`.
  - iOS 호출(`package` 없음)의 기존 결과는 그대로.
- 진입점: `@pragma('vm:entry-point') Future<void> androidIngestMain()` — `iosIngestMain`과 같은 동작. 공통 본문을 private 함수로 뽑아 두 진입점이 호출한다.
- `android_bridge.dart`: `class AndroidBridge { const AndroidBridge({MethodChannel channel = androidChannel}); Future<void> setAllowedPackages(List<String>); Future<bool> listenerEnabled(); Future<void> openListenerSettings(); Future<List<RecentPackage>> recentPackages(); }`, `const MethodChannel androidChannel = MethodChannel('spend_ledger/android')`, `class RecentPackage { String package; String label; }`(Equatable, `fromMap({package, label})`). 채널이 없으면(`MissingPluginException`) 각각 무동작·false·빈 목록.
- `bootstrap()`: Android에서 `AndroidBridge().setAllowedPackages(settings.notificationPackages)`를 호출(실패는 기록만). `buildIngestDeps`는 `SqlSeenRepository(db)`를 넘긴다.

- [ ] **Step 1: 실패하는 테스트 작성**
  - `sourceForPackage`: null→iosShortcut, 삼성 메시지→androidSms, `com.kbcard.cxh.appcard`→androidApp.
  - `notificationFingerprint`: 같은 입력 같은 값, 패키지만 달라도 다른 값, 길이 16.
  - seen repo: 처음 claim true, 9분 뒤 같은 지문 false, 11분 뒤 true, release 뒤 즉시 true.
  - ingest_entry: `ingest {text, sender, package: 삼성 메시지, postedAtMs}` → 저장된 거래의 receivedAt이 postedAtMs, source androidSms(저장된 rawText/sender로 확인 가능한 범위에서), 결과 `stored`.
  - 같은 호출 두 번 → 두 번째 `{result: 'seen'}`, 거래 1건.
  - 저장 전 실패(예: 저장소 `saveIncoming`이 던지는 fake) → `error`, 그 뒤 같은 호출이 `seen`이 아니라 다시 처리됨.
  - `refresh` → `{result: 'refreshed'}`, `MemoryWidgetGateway.last`가 채워짐.
  - 기존 iOS `ingest {text, sender}` 테스트 그대로 통과.
  - AppSettings: 기본 notificationPackages, JSON 왕복, 키 없는 JSON → 기본값.
  - AndroidBridge: mock 채널로 각 메서드의 메서드명·인자, `MissingPluginException` 시 기본값.
  - DB v1→v2 업그레이드: v1 스키마로 만든 ffi DB를 v2로 열면 `seen_notifications` 존재(테스트 헬퍼가 버전 지정 열기를 지원하도록 `memory_db.dart` 확장 가능).
- [ ] **Step 2: 해당 테스트 실행, FAIL 확인**
- [ ] **Step 3: 구현**
- [ ] **Step 4: 전체 `flutter test`, `flutter analyze` 0건**
- [ ] **Step 5: 커밋** `feat(spend_ledger): Android 알림 수집 Dart 진입점과 재게시 중복 거르기`

### Task 3: Kotlin 알림 리스너와 백그라운드 엔진

**Files:**
- Create (`android/app/src/main/kotlin/com/spiralmomentum/spend_ledger/`): `NotificationExtraction.kt`, `IngestQueue.kt`, `IngestEngineHost.kt`, `PaymentNotificationListener.kt`, `NativeStores.kt`(허용 앱·최근 앱·진단 기록 SharedPreferences)
- Modify: `MainActivity.kt`(채널 `spend_ledger/android`, `spend_ledger/diagnostics`), `AndroidManifest.xml`(서비스), `android/app/build.gradle.kts`(`testImplementation("junit:junit:4.13.2")`)
- Modify: `apps/spend_ledger/README.md`(Android 설치·권한·확인 질문 절 추가)
- Test: `android/app/src/test/kotlin/com/spiralmomentum/spend_ledger/NotificationExtractionTest.kt`, `IngestQueueTest.kt`, `NativeStoresLogicTest.kt`(순수 로직만)

**Interfaces:**
- Consumes: Task 2의 채널 계약(`ready`, `ingest {text, sender?, package, postedAtMs}` → `{result, dartMs, ...}`, `refresh`), 진입점 이름 `androidIngestMain`, `spend_ledger/android` 메서드명(`setAllowedPackages {packages: List<String>}`, `listenerEnabled`, `openListenerSettings`, `recentPackages` → `List<{package, label}>`), 기본 허용 앱 2개.
- Produces (순수 Kotlin, 안드로이드 클래스 의존 없음):
  - `data class MessageFields(val text: String?, val timestampMs: Long?, val sender: String?)`
  - `data class NotificationFields(val packageName: String, val isGroupSummary: Boolean, val isOngoing: Boolean, val title: String?, val text: String?, val bigText: String?, val messages: List<MessageFields>, val postTimeMs: Long)`
  - `data class ExtractedMessage(val packageName: String, val text: String, val sender: String?, val postedAtMs: Long)`
  - `fun extractMessage(f: NotificationFields): ExtractedMessage?` — 요약·진행 중이면 null. `messages`가 있으면 마지막 메시지(text 비면 null), 시각은 그 메시지 timestamp 없으면 postTime, 보낸 사람은 그 메시지 sender ?: title. 없으면 `bigText` → `text`(공백뿐이면 null), 보낸 사람 title.
  - `fun shouldHandle(packageName: String, allowed: Set<String>): Boolean`
  - `class IngestQueue<T>` — `submit(item)`: 준비 전이면 쌓고 준비됐으면 바로 전달, `markReady()`: 쌓인 것을 순서대로 전달, `reset()`: 준비 상태 해제(엔진 재시작 시). 전달 함수는 생성자 인자.
  - 진단 기록: iOS와 같은 JSON 필드 `{at, path, engineMs, dartMs?, totalMs, result}`, `path`는 `listener`, 최근 20건 유지. 순수 함수 `appendDiagnostic(existingJson: String?, entry: Map<String, Any?>, limit: Int = 20): String`.
  - 최근 알림 앱: 패키지 이름만, 최근 20개 중복 없이 최신순. 순수 함수 `pushRecent(existing: List<String>, pkg: String, limit: Int = 20): List<String>`.
- `PaymentNotificationListener`: `onNotificationPosted`에서 모든 알림의 패키지를 최근 앱에 기록(자기 앱 제외), 허용 앱이면 `extractMessage` 후 `IngestEngineHost.submit`. `onListenerConnected`에서 `ACTION_DATE_CHANGED` 수신기를 등록하고 받으면 `IngestEngineHost.refresh()`, `onListenerDisconnected`에서 해제. 허용 목록이 SharedPreferences에 없으면 기본 2개.
- `IngestEngineHost`(object): 첫 요청 때 `FlutterInjector.instance().flutterLoader()` 초기화 후 `FlutterEngine(context)`에서 `DartEntrypoint(appBundlePath, "androidIngestMain")` 실행. `ready`를 받으면 큐 `markReady`. 준비 10초, 응답 15초 제한. 시간 초과·실패 결과(`ready-timeout`, `ingest-timeout`, `engine-run-failed`)도 진단에 남긴다. 엔진은 서비스가 살아 있는 동안 유지하고, 실패하면 버리고 다음 요청 때 다시 만든다.
- `MainActivity.configureFlutterEngine`: `spend_ledger/android` 4개 메서드와 `spend_ledger/diagnostics`의 `list`(진단 JSON 문자열). `listenerEnabled`는 `NotificationManagerCompat.getEnabledListenerPackages(context).contains(packageName)`, `openListenerSettings`는 `Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS`. `recentPackages`는 PackageManager로 라벨을 붙인다(조회 실패 시 패키지 이름).
- Manifest: `<service android:name=".PaymentNotificationListener" android:exported="true" android:label="지출 위젯 결제 알림 수집" android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE"><intent-filter><action android:name="android.service.notification.NotificationListenerService"/></intent-filter></service>`. Android 11+에서 다른 앱 라벨 조회가 필요하면 `<queries>`에 `<intent><action android:name="android.intent.action.MAIN"/></intent>` 추가.
- README: '2단계 Android' 절 — `flutter install` 설치, 알림 접근 허용, 삼성 '절전 앱'/'사용하지 않는 앱 자동 해제'에서 제외, 설계 10.6의 질문 4개와 진단 값 보는 법.

- [ ] **Step 1: 실패하는 Kotlin 테스트 작성**
  - extraction: MessagingStyle 2건 → 마지막 메시지 text·timestamp·sender, 마지막 메시지 sender null → title, 요약 알림 → null, 진행 중 → null, messages 없음 → bigText 우선, bigText 없음 → text, 공백뿐 → null, 마지막 메시지 timestamp null → postTime.
  - shouldHandle: 허용 목록 포함/미포함.
  - IngestQueue: 준비 전 3건 submit → 전달 0, markReady → 순서대로 3건, 이후 submit 즉시 전달, reset 뒤 다시 쌓임.
  - appendDiagnostic: null 시작, 21건째에 가장 오래된 것 제거, 필드 보존. pushRecent: 중복 시 맨 앞으로 이동, 21개째 잘림.
- [ ] **Step 2: `cd android && ./gradlew :app:testDebugUnitTest` 실행, FAIL 확인**
- [ ] **Step 3: 구현(순수 로직 → 서비스·호스트·MainActivity·매니페스트·README)**
- [ ] **Step 4: Kotlin 테스트 PASS, `flutter build apk --debug` 성공, `flutter test`·`flutter analyze` 그대로 통과**
- [ ] **Step 5: 커밋** `feat(spend_ledger): Android 알림 리스너 수집`

### Task 4: 알림 수집 설정 화면

**Files:**
- Create: `lib/features/ingest/presentation/notification_access_page.dart`, `lib/features/settings/presentation/allowed_apps_page.dart`
- Modify: `lib/features/settings/presentation/settings_page.dart`, `lib/features/settings/presentation/settings_cubit.dart`, `lib/features/ingest/presentation/diagnostics_page.dart`(문구가 단축어 전용이면 플랫폼 중립으로)
- Test: `test/features/ingest/notification_access_page_test.dart`, `test/features/settings/allowed_apps_page_test.dart`, `test/features/settings/settings_cubit_test.dart`·`settings_page_test.dart`(새 파일)

**Interfaces:**
- Consumes: Task 2 `AndroidBridge`, `RecentPackage`, `AppSettings.notificationPackages`, `defaultNotificationPackages`.
- `SettingsCubit`에 `Future<void> setNotificationPackages(List<String> packages)` — 설정 저장 후 `AndroidBridge.setAllowedPackages` 호출. 브리지는 생성자 인자(기본 `const AndroidBridge()`)로 받는다.
- 설정 화면: `defaultTargetPlatform == TargetPlatform.android`면 '단축어 설정 안내' 대신 '알림 수집 설정'(→ `NotificationAccessPage`), 그 밖에는 기존 그대로. '수집 진단'은 두 플랫폼 모두.
- `NotificationAccessPage`: 알림 접근 켜짐/꺼짐 표시, '알림 접근 설정 열기' 버튼, 앱으로 돌아오면(`AppLifecycleState.resumed`) 상태 다시 확인, 삼성 절전 예외 안내 문구, '수집할 앱' 항목(→ `AllowedAppsPage`).
- `AllowedAppsPage`: 허용 앱 목록(문자 앱 2개는 이름 '삼성 메시지', 'Google 메시지'로 표시, 그 밖은 최근 앱 라벨 또는 패키지 이름)과 삭제, '최근 알림을 보낸 앱'에서 추가(이미 허용된 앱 제외), 패키지 이름 직접 입력 추가, 목록이 비면 "수집할 앱이 없어 결제 알림을 받지 않습니다." 경고.

- [ ] **Step 1: 실패하는 테스트 작성** — cubit: `setNotificationPackages`가 저장소와 브리지(mocktail) 둘 다 호출. 설정 화면: Android 오버라이드에서 '알림 수집 설정' 보이고 '단축어 설정 안내' 없음, iOS에서는 반대. 접근 페이지: 브리지가 false면 '꺼짐', 버튼 탭 시 `openListenerSettings` 호출, resumed 뒤 true면 '켜짐'. 허용 앱 페이지: 기본 2개 표시, 삭제 시 cubit 호출, 최근 앱에서 이미 허용된 앱은 안 보임, 추가 시 목록에 붙음, 모두 지우면 경고 문구.
- [ ] **Step 2: FAIL 확인**
- [ ] **Step 3: 구현**
- [ ] **Step 4: 전체 `flutter test`, `flutter analyze` 0건**
- [ ] **Step 5: 커밋** `feat(spend_ledger): Android 알림 수집 설정 화면`

### Task 5: Android 홈 위젯 소·중·대

**Files:**
- Modify: `pubspec.yaml`(`home_widget` 추가), `lib/features/widget_sync/domain/widget_entries.dart`, `lib/features/ingest/domain/ingest.dart`(`refreshOutputs`의 호출), `lib/app/bootstrap.dart`, `lib/app/spend_ledger_app.dart`(위젯 탭 라우팅)
- Create: `lib/features/widget_sync/data/home_widget_gateway.dart`
- Create (Kotlin): `WidgetTexts.kt`(순수), `SpendWidgetProviders.kt`(Small/Medium/Large), `res/layout/widget_small.xml`, `widget_medium.xml`, `widget_large.xml`, `res/xml/widget_small_info.xml`, `widget_medium_info.xml`, `widget_large_info.xml`, 필요한 drawable·strings
- Modify: `AndroidManifest.xml`(receiver 3개, MainActivity에 home_widget 실행 인텐트 필터), `README.md`(위젯 추가 방법·확인 질문 3)
- Test: `test/features/widget_sync/widget_entries_test.dart`(기존 파일에 추가), `test/features/widget_sync/home_widget_gateway_test.dart`, `test/app/spend_ledger_app_test.dart`(기존 파일에 추가), `android/app/src/test/kotlin/com/spiralmomentum/spend_ledger/WidgetTextsTest.kt`

**Interfaces:**
- `widgetEntries(LedgerSummary s, {required bool hideAmounts, required DateTime asOf})` — 기존 키에 `'asOf'`: `M/d HH:mm`(예 `11/28 09:05`) 추가. `refreshOutputs`는 `d.now()`를 넘긴다.
- `class HomeWidgetGateway implements WidgetGateway` — 각 항목을 `HomeWidget.saveWidgetData<String>`로 저장한 뒤 `HomeWidget.updateWidget(qualifiedAndroidName: ...)`을 세 provider(`com.spiralmomentum.spend_ledger.SmallSpendWidget`, `MediumSpendWidget`, `LargeSpendWidget`)에 호출. 저장·갱신 함수는 생성자 인자로 주입 가능(기본값은 HomeWidget 정적 메서드)해 테스트에서 가짜로 바꾼다. `buildIngestDeps`는 Android에서 이것을, 그 밖에서는 `NoopWidgetGateway`를 쓴다.
- 위젯 탭: 위젯 전체 → `spendledger://home`, 대기 건수 표시 → `spendledger://candidates`. Dart는 시작 시 `HomeWidget.initiallyLaunchedFromHomeWidget()`, 실행 중에는 `HomeWidget.widgetClicked`를 받아 host가 `candidates`면 `AppRoutes.candidates`를 연다. URI→라우트 변환은 순수 함수 `String? routeForWidgetUri(Uri? uri)`(candidates → `AppRoutes.candidates`, 그 밖 null)로 둔다.
- Kotlin 순수: `data class WidgetTexts(val total: String, val ratio: String, val today: String, val daily: String, val elapsedPercent: Int, val ratioPercent: Int?, val top: List<String>, val recent: List<String>, val pending: Int, val asOf: String)`, `fun widgetTexts(data: Map<String, String?>): WidgetTexts` — 빈 문자열·누락은 표시용 대체값으로: total 빈 값 → `"•••"`(금액 숨김), ratio 빈 값 → `"예산 없음"`, 그 밖 `"$ratio%"`; top/recent는 빈 항목 제외; pending 파싱 실패 → 0.
- 크기: 소 2×2(`minWidth 110dp`, `minHeight 110dp`), 중 4×2(250×110), 대 4×4(250×250). 대기 건수가 0이면 그 뷰를 숨긴다.

- [ ] **Step 1: 실패하는 테스트 작성** — widgetEntries: asOf 형식, 기존 키 유지. gateway: 가짜 저장 함수가 모든 키를 받고 provider 3개 갱신 호출. `routeForWidgetUri`: candidates→후보 라우트, home·null→null. Kotlin `WidgetTextsTest`: 금액 숨김(빈 total)→`•••`, ratio 빈 값→`예산 없음`, `"42"`→`42%`·ratioPercent 42, top 3개 중 빈 것 제외, pending `"x"`→0.
- [ ] **Step 2: FAIL 확인(Dart, Kotlin 둘 다)**
- [ ] **Step 3: 구현**
- [ ] **Step 4: 전체 `flutter test`, `flutter analyze` 0건, `./gradlew :app:testDebugUnitTest` PASS, `flutter build apk --debug` 성공, `flutter build ios --no-codesign` 성공**
- [ ] **Step 5: 커밋** `feat(spend_ledger): Android 홈 위젯 소·중·대`
