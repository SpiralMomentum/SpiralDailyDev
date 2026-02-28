# News Reader - Remaining Spec Implementation Design

## Goal

news_reader.md 스펙의 미구현 항목 14개를 완성하여 Phase 4(Production Release) 수준으로 끌어올린다.

## Approach

Firebase는 Mock/Interface 패턴을 사용한다. 실제 Firebase 패키지를 추가하지 않고, 인터페이스 정의 + 로컬 Mock 구현으로 아키텍처를 검증한다.

## Items

### Group A: UI/UX Enhancements

**A1. Bottom Navigation**
- GoRouter의 `ShellRoute` + `NavigationBar` (Material 3) 적용
- 4개 탭: Feed, Bookmarks, Search, Settings
- 기존 AppBar 아이콘 네비게이션을 BottomNav으로 교체
- 현재 탭 상태 유지 (각 탭별 Navigator)

**A2. Share Functionality**
- `share_plus` 패키지로 ArticleDetailPage에 공유 버튼 추가
- ArticleDetailBloc에 `ArticleDetailShareRequested` 이벤트 추가
- 공유 콘텐츠: 기사 제목 + URL

**A3. Image Pipeline**
- `Image.network`를 `CachedNetworkImage`로 교체 (cached_network_image)
- `memCacheWidth`/`memCacheHeight`로 메모리 최적화
- placeholder: Shimmer, errorWidget: 대체 아이콘
- 적용 위치: ArticleCard, ArticleDetailPage

**A4. Accessibility**
- 인터랙티브 위젯에 `Semantics` 추가
- 장식용 이미지에 `excludeFromSemantics: true`
- 터치 타겟 >= 48x48dp 검증
- 적용 위치: ArticleCard, BookmarksPage, CommentTile, SearchPage

**A5. Haptic Feedback**
- `HapticFeedback.mediumImpact()`: 북마크 토글, 댓글 작성 완료
- `HapticFeedback.lightImpact()`: Pull-to-Refresh 완료
- 기존 `HapticService` 활용

### Group B: Infrastructure

**B1. Article Cache SQL**
- `SqlArticleCacheDataSource` 구현 (article_cache 테이블 사용)
- TTL 5분 (300,000ms)
- cache_key: `"feed:{category}:{cursor}"` 형태
- `ArticleRepositoryImpl`에서 캐시 -> 네트워크 순서로 조회

**B2. Memory Pressure Handling**
- `App` 위젯에 `WidgetsBindingObserver` mixin
- `didHaveMemoryPressure()` 콜백에서 `imageCache.clear()` 호출
- 프리페치된 데이터 해제

**B3. Code Splitting / Deferred Loading**
- Onboarding, Settings 화면을 `deferred as` 키워드로 분리
- `loadLibrary()` 호출 후 위젯 렌더링
- GoRouter에서 deferred import 적용

**B4. State Restoration**
- `PageStorageKey` 적용: Feed, Bookmarks, Search 스크롤 위치
- ShellRoute 내 각 탭이 독립적으로 스크롤 위치 유지

### Group C: Firebase Mock Interfaces

**C1. Analytics / Crashlytics / Remote Config**
- `AnalyticsService` 인터페이스 + `MockAnalyticsService`
- `CrashlyticsService` 인터페이스 + `MockCrashlyticsService`
- `RemoteConfigService` 인터페이스 + `MockRemoteConfigService`
- ServiceLocator에 등록

**C2. Forced Update**
- `RemoteConfigService`에서 `min_version`, `latest_version` 조회
- 앱 버전 비교 로직
- 강제 업데이트 다이얼로그 (앱 사용 차단)
- 소프트 업데이트 다이얼로그 (권유)

**C3. Push Notification Interface**
- `PushNotificationService` 인터페이스
- `MockPushNotificationService` (로컬 구현)
- 카테고리별 토픽 구독/해제

**C4. Background Sync Interface**
- `BackgroundSyncService` 인터페이스
- `MockBackgroundSyncService` (SyncBookmarks 호출)

### Group D: Platform Configuration

**D1. Deep Linking**
- AndroidManifest.xml: intent-filter (`news-reader://article/{id}`)
- Info.plist: URL scheme (`news-reader`)
- GoRouter에서 딥링크 경로 처리 (이미 `/article/:id` 라우트 존재)

## Testing Strategy

- 각 항목별 Unit/Widget 테스트 추가
- 기존 125개 테스트 유지
- 목표: 전체 커버리지 >= 80%
