# News Reader Remaining Spec Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** news_reader.md 스펙의 미구현 14개 항목을 완성하여 Phase 4 수준으로 끌어올린다.

**Architecture:** Clean Architecture (Domain/Data/External/Presentation) 유지. Firebase는 Mock/Interface 패턴 (실제 패키지 없음). 기존 125개 테스트를 깨뜨리지 않으면서 각 항목별 테스트 추가.

**Tech Stack:** Flutter 3.41, Dart 3.11, flutter_bloc, go_router (ShellRoute), get_it, sqflite, cached_network_image, share_plus, mocktail

**Working Directory:** `/Users/gyubinhwang/AndroidStudioProjects/spiral_dev/.worktrees/news-reader/apps/news_reader/`

**Test Command:** `flutter test` (from working directory)

**Analyze Command:** `flutter analyze` (from working directory)

---

## Task 1: Firebase Mock Service Interfaces

Firebase 없이 동일한 계약(contract)을 제공하는 서비스 인터페이스와 Mock 구현체를 생성한다.
다른 Task (Forced Update, Push Notification)의 의존성이므로 가장 먼저 구현한다.

**Files:**
- Create: `lib/core/services/analytics_service.dart`
- Create: `lib/core/services/crashlytics_service.dart`
- Create: `lib/core/services/remote_config_service.dart`
- Create: `test/core/services/remote_config_service_test.dart`
- Modify: `lib/app/di/service_locator.dart`

**Step 1: Create AnalyticsService interface + Mock**

```dart
// lib/core/services/analytics_service.dart
abstract class AnalyticsService {
  void trackEvent(String name, [Map<String, Object>? params]);
  void trackScreenView(String screenName);
  void setUserProperty(String name, String value);
}

class MockAnalyticsService implements AnalyticsService {
  final List<String> trackedEvents = [];

  @override
  void trackEvent(String name, [Map<String, Object>? params]) {
    trackedEvents.add(name);
  }

  @override
  void trackScreenView(String screenName) {
    trackedEvents.add('screen:$screenName');
  }

  @override
  void setUserProperty(String name, String value) {}
}
```

**Step 2: Create CrashlyticsService interface + Mock**

```dart
// lib/core/services/crashlytics_service.dart
abstract class CrashlyticsService {
  void recordError(Object error, StackTrace? stackTrace, {bool fatal = false});
  void log(String message);
  void setUserId(String id);
}

class MockCrashlyticsService implements CrashlyticsService {
  final List<String> logs = [];

  @override
  void recordError(Object error, StackTrace? stackTrace, {bool fatal = false}) {
    logs.add('error: $error');
  }

  @override
  void log(String message) {
    logs.add(message);
  }

  @override
  void setUserId(String id) {}
}
```

**Step 3: Create RemoteConfigService interface + Mock**

```dart
// lib/core/services/remote_config_service.dart
abstract class RemoteConfigService {
  Future<void> fetchAndActivate();
  String getString(String key, {String defaultValue = ''});
  int getInt(String key, {int defaultValue = 0});
  bool getBool(String key, {bool defaultValue = false});
}

class MockRemoteConfigService implements RemoteConfigService {
  MockRemoteConfigService({Map<String, dynamic>? overrides})
      : _values = {..._defaults, ...?overrides};

  final Map<String, dynamic> _values;

  static const Map<String, dynamic> _defaults = {
    'min_version': '1.0.0',
    'latest_version': '1.0.0',
    'force_update_enabled': false,
  };

  @override
  Future<void> fetchAndActivate() async {}

  @override
  String getString(String key, {String defaultValue = ''}) =>
      _values[key] as String? ?? defaultValue;

  @override
  int getInt(String key, {int defaultValue = 0}) =>
      _values[key] as int? ?? defaultValue;

  @override
  bool getBool(String key, {bool defaultValue = false}) =>
      _values[key] as bool? ?? defaultValue;
}
```

**Step 4: Write test for RemoteConfigService**

```dart
// test/core/services/remote_config_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:apps.news_reader/core/services/remote_config_service.dart';

void main() {
  group('MockRemoteConfigService', () {
    test('returns default values', () {
      final service = MockRemoteConfigService();
      expect(service.getString('min_version'), '1.0.0');
      expect(service.getString('latest_version'), '1.0.0');
      expect(service.getBool('force_update_enabled'), false);
    });

    test('returns overridden values', () {
      final service = MockRemoteConfigService(overrides: {
        'min_version': '2.0.0',
        'force_update_enabled': true,
      });
      expect(service.getString('min_version'), '2.0.0');
      expect(service.getBool('force_update_enabled'), true);
    });

    test('returns default for unknown keys', () {
      final service = MockRemoteConfigService();
      expect(service.getString('unknown', defaultValue: 'fallback'), 'fallback');
      expect(service.getInt('unknown', defaultValue: 42), 42);
      expect(service.getBool('unknown', defaultValue: true), true);
    });

    test('fetchAndActivate completes without error', () async {
      final service = MockRemoteConfigService();
      await expectLater(service.fetchAndActivate(), completes);
    });
  });
}
```

**Step 5: Run tests**

Run: `flutter test test/core/services/remote_config_service_test.dart`
Expected: All tests PASS

**Step 6: Register services in ServiceLocator**

Add to `lib/app/di/service_locator.dart` (after existing data source registrations):

```dart
// Core Services
import 'package:apps.news_reader/core/services/analytics_service.dart';
import 'package:apps.news_reader/core/services/crashlytics_service.dart';
import 'package:apps.news_reader/core/services/remote_config_service.dart';

// Inside setupLocatorSingleton(), add after the search remote data source:
getIt
  ..registerLazySingleton<AnalyticsService>(
    () => MockAnalyticsService(),
  )
  ..registerLazySingleton<CrashlyticsService>(
    () => MockCrashlyticsService(),
  )
  ..registerLazySingleton<RemoteConfigService>(
    () => MockRemoteConfigService(),
  );
```

**Step 7: Run all tests**

Run: `flutter test`
Expected: All 125+ tests PASS

**Step 8: Commit**

```bash
git add lib/core/services/ test/core/services/ lib/app/di/service_locator.dart
git commit -m "feat(news_reader): add Firebase mock service interfaces (Analytics, Crashlytics, RemoteConfig)"
```

---

## Task 2: Bottom Navigation with ShellRoute

기존 플랫 라우트 구조를 ShellRoute + NavigationBar (Material 3)로 변경한다.
Feed, Bookmarks, Search, Settings 4개 탭. 각 탭은 독립적 Navigator를 갖는다.

**Files:**
- Create: `lib/app/route/app_shell.dart`
- Modify: `lib/app/route/app_router.dart`
- Modify: `lib/features/news_feed/presentation/views/news_feed_page.dart`
- Modify: `lib/features/bookmarks/presentation/views/bookmarks_page.dart`
- Modify: `lib/features/search/presentation/views/search_page.dart`
- Modify: `lib/features/settings/presentation/views/settings_page.dart`
- Modify: `test/app/route/app_router_test.dart`

**Step 1: Create AppShell widget**

```dart
// lib/app/route/app_shell.dart
import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTap,
  });

  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.newspaper_outlined),
            selectedIcon: Icon(Icons.newspaper),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Bookmarks',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
```

**Step 2: Rewrite app_router.dart with ShellRoute**

Replace the entire `createRouter` function in `lib/app/route/app_router.dart`:

```dart
import 'package:apps.news_reader/app/di/service_locator.dart';
import 'package:apps.news_reader/app/route/app_routes.dart';
import 'package:apps.news_reader/app/route/app_shell.dart';
import 'package:apps.news_reader/features/article_detail/domain/usecases/get_article_detail.dart';
import 'package:apps.news_reader/features/bookmarks/domain/usecases/get_bookmarks.dart';
import 'package:apps.news_reader/features/bookmarks/domain/usecases/toggle_bookmark.dart';
import 'package:apps.news_reader/features/comments/domain/usecases/add_comment.dart';
import 'package:apps.news_reader/features/comments/domain/usecases/watch_comments.dart';
import 'package:apps.news_reader/features/comments/presentation/bloc/comments_bloc.dart';
import 'package:apps.news_reader/features/comments/presentation/bloc/comments_event.dart';
import 'package:apps.news_reader/features/comments/presentation/views/comments_page.dart';
import 'package:apps.news_reader/features/news_feed/domain/usecases/get_article_feed.dart';
import 'package:apps.news_reader/features/news_feed/presentation/bloc/news_feed_bloc.dart';
import 'package:apps.news_reader/features/news_feed/presentation/bloc/news_feed_event.dart';
import 'package:apps.news_reader/features/news_feed/presentation/views/news_feed_page.dart';
import 'package:apps.news_reader/features/article_detail/presentation/bloc/article_detail_bloc.dart';
import 'package:apps.news_reader/features/article_detail/presentation/bloc/article_detail_event.dart';
import 'package:apps.news_reader/features/article_detail/presentation/views/article_detail_page.dart';
import 'package:apps.news_reader/features/bookmarks/presentation/cubit/bookmarks_cubit.dart';
import 'package:apps.news_reader/features/bookmarks/presentation/views/bookmarks_page.dart';
import 'package:apps.news_reader/features/onboarding/presentation/views/onboarding_page.dart';
import 'package:apps.news_reader/features/search/domain/repositories/search_repository.dart';
import 'package:apps.news_reader/features/search/domain/usecases/search_articles.dart';
import 'package:apps.news_reader/features/search/presentation/cubit/search_cubit.dart';
import 'package:apps.news_reader/features/search/presentation/views/search_page.dart';
import 'package:apps.news_reader/features/settings/domain/repositories/settings_repository.dart';
import 'package:apps.news_reader/features/settings/domain/usecases/get_settings.dart';
import 'package:apps.news_reader/features/settings/domain/usecases/update_settings.dart';
import 'package:apps.news_reader/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:apps.news_reader/features/settings/presentation/views/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>();

const _tabPaths = ['/feed', '/bookmarks', '/search', '/settings'];

GoRouter createRouter({String? initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation ?? AppRoutes.feed.path,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding.path,
        builder: (context, state) {
          return OnboardingPage(
            settingsRepository: getIt.get<SettingsRepository>(),
            onCompleted: () => context.go(AppRoutes.feed.path),
          );
        },
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          final location = state.uri.path;
          int currentIndex = 0;
          for (int i = 0; i < _tabPaths.length; i++) {
            if (location.startsWith(_tabPaths[i])) {
              currentIndex = i;
              break;
            }
          }
          return AppShell(
            currentIndex: currentIndex,
            onTap: (index) => context.go(_tabPaths[index]),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.feed.path,
            builder: (context, state) {
              return BlocProvider(
                create: (_) => NewsFeedBloc(
                  getArticleFeed: getIt.get<GetArticleFeed>(),
                  toggleBookmark: getIt.get<ToggleBookmark>(),
                )..add(const NewsFeedStarted()),
                child: const NewsFeedPage(),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.bookmarks.path,
            builder: (context, state) {
              return BlocProvider(
                create: (_) => BookmarksCubit(
                  getBookmarks: getIt.get<GetBookmarks>(),
                  toggleBookmark: getIt.get<ToggleBookmark>(),
                )..loadBookmarks(),
                child: const BookmarksPage(),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.search.path,
            builder: (context, state) {
              return BlocProvider(
                create: (_) => SearchCubit(
                  searchArticles: getIt.get<SearchArticles>(),
                  repository: getIt.get<SearchRepository>(),
                ),
                child: const SearchPage(),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.settings.path,
            builder: (context, state) {
              return BlocProvider(
                create: (_) => SettingsCubit(
                  getSettings: getIt.get<GetSettings>(),
                  updateSettings: getIt.get<UpdateSettings>(),
                )..loadSettings(),
                child: const SettingsPage(),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.articleDetail.path,
        builder: (context, state) {
          final articleId = state.pathParameters['id']!;
          return BlocProvider(
            create: (_) => ArticleDetailBloc(
              getArticleDetail: getIt.get<GetArticleDetail>(),
              toggleBookmark: getIt.get<ToggleBookmark>(),
            )..add(ArticleDetailStarted(articleId)),
            child: const ArticleDetailPage(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.comments.path,
        builder: (context, state) {
          final articleId = state.pathParameters['id']!;
          return BlocProvider(
            create: (_) => CommentsBloc(
              watchComments: getIt.get<WatchComments>(),
              addComment: getIt.get<AddComment>(),
            )..add(CommentsStarted(articleId)),
            child: CommentsPage(articleId: articleId),
          );
        },
      ),
    ],
  );
}
```

**Step 3: Remove navigation icons from NewsFeedPage AppBar**

In `lib/features/news_feed/presentation/views/news_feed_page.dart`, remove the `actions` list from AppBar (search, bookmarks, settings icons). These are now in BottomNav.

Replace the AppBar section:
```dart
// BEFORE:
appBar: AppBar(
  title: const Text('News Reader'),
  actions: [
    IconButton(
      icon: const Icon(Icons.search),
      onPressed: () => context.push(AppRoutes.search.path),
    ),
    IconButton(
      icon: const Icon(Icons.bookmark_outline),
      onPressed: () => context.push(AppRoutes.bookmarks.path),
    ),
    IconButton(
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => context.push(AppRoutes.settings.path),
    ),
  ],
),

// AFTER:
appBar: AppBar(
  title: const Text('News Reader'),
),
```

Also remove the `import 'package:apps.news_reader/app/route/app_routes.dart';` if no longer used.

**Step 4: Update router test**

```dart
// test/app/route/app_router_test.dart
import 'package:apps.news_reader/app/di/service_locator.dart';
import 'package:apps.news_reader/app/route/app_router.dart';
import 'package:apps.news_reader/app/route/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() async {
    await ServiceLocator.setupLocatorSingleton();
  });

  tearDown(() {
    getIt.reset();
  });

  group('AppRouter', () {
    test('creates router with default initial location /feed', () {
      final router = createRouter();
      expect(router.routerDelegate, isNotNull);
    });

    test('creates router with onboarding initial location', () {
      final router = createRouter(
        initialLocation: AppRoutes.onboarding.path,
      );
      expect(router.routerDelegate, isNotNull);
    });

    test('all route paths are defined', () {
      expect(AppRoutes.values.length, 7);
      expect(AppRoutes.feed.path, '/feed');
      expect(AppRoutes.onboarding.path, '/onboarding');
      expect(AppRoutes.articleDetail.path, '/article/:id');
      expect(AppRoutes.comments.path, '/article/:id/comments');
      expect(AppRoutes.bookmarks.path, '/bookmarks');
      expect(AppRoutes.search.path, '/search');
      expect(AppRoutes.settings.path, '/settings');
    });
  });
}
```

**Step 5: Run all tests**

Run: `flutter test`
Expected: All tests PASS

**Step 6: Commit**

```bash
git add lib/app/route/ lib/features/news_feed/presentation/views/news_feed_page.dart test/app/route/
git commit -m "feat(news_reader): add bottom navigation with ShellRoute (Feed/Bookmarks/Search/Settings)"
```

---

## Task 3: Share Functionality

ArticleDetailPage에 공유 기능을 추가한다. `share_plus` 패키지를 사용한다.

**Files:**
- Modify: `pubspec.yaml` (add share_plus)
- Modify: `lib/features/article_detail/presentation/bloc/article_detail_event.dart`
- Modify: `lib/features/article_detail/presentation/bloc/article_detail_bloc.dart`
- Modify: `lib/features/article_detail/presentation/views/article_detail_page.dart`
- Modify: `test/features/article_detail/presentation/bloc/article_detail_bloc_test.dart`

**Step 1: Add share_plus to pubspec.yaml**

Add under dependencies:
```yaml
  # Share
  share_plus: ^7.0.0
```

Run: `flutter pub get`

**Step 2: Add ShareRequested event**

Add to `lib/features/article_detail/presentation/bloc/article_detail_event.dart`:
```dart
class ArticleDetailShareRequested extends ArticleDetailEvent {
  const ArticleDetailShareRequested();
}
```

**Step 3: Add share handler in BLoC**

Modify `lib/features/article_detail/presentation/bloc/article_detail_bloc.dart`:
- Add import: `import 'package:share_plus/share_plus.dart';`
- Register handler in constructor: `on<ArticleDetailShareRequested>(_onShareRequested);`
- Add handler method:
```dart
Future<void> _onShareRequested(
  ArticleDetailShareRequested event,
  Emitter<ArticleDetailState> emit,
) async {
  final article = state.article;
  if (article == null) return;
  await SharePlus.instance.share(
    ShareParams(text: '${article.title}\nnews-reader://article/${article.id}'),
  );
}
```

**Step 4: Add share button to ArticleDetailPage**

In `lib/features/article_detail/presentation/views/article_detail_page.dart`, add share icon to AppBar actions (before comment icon):
```dart
IconButton(
  icon: const Icon(Icons.share_outlined),
  onPressed: () {
    context
        .read<ArticleDetailBloc>()
        .add(const ArticleDetailShareRequested());
  },
),
```

**Step 5: Add test for share event**

In `test/features/article_detail/presentation/bloc/article_detail_bloc_test.dart`, add a test:
```dart
blocTest<ArticleDetailBloc, ArticleDetailState>(
  'does not throw when share requested with no article',
  build: () => ArticleDetailBloc(
    getArticleDetail: mockGetArticleDetail,
    toggleBookmark: mockToggleBookmark,
  ),
  act: (bloc) => bloc.add(const ArticleDetailShareRequested()),
  expect: () => <ArticleDetailState>[],
);
```

**Step 6: Run all tests**

Run: `flutter test`
Expected: All tests PASS

**Step 7: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/features/article_detail/ test/features/article_detail/
git commit -m "feat(news_reader): add share functionality to article detail page"
```

---

## Task 4: Image Pipeline with CachedNetworkImage

`Image.network`을 `CachedNetworkImage`로 교체하여 이미지 캐싱 + 메모리 최적화를 적용한다.

**Files:**
- Modify: `lib/features/news_feed/presentation/views/news_feed_page.dart`
- Modify: `lib/features/article_detail/presentation/views/article_detail_page.dart`

**Step 1: Replace Image.network in NewsFeedPage (_ArticleCard)**

In `lib/features/news_feed/presentation/views/news_feed_page.dart`, replace the `Image.network` widget in `_ArticleCard`:

Add import: `import 'package:cached_network_image/cached_network_image.dart';`

```dart
// BEFORE:
Image.network(
  article.imageUrl,
  fit: BoxFit.cover,
  errorBuilder: (_, __, ___) => Container(
    color: theme.colorScheme.surfaceContainerHighest,
    child: Icon(Icons.image, color: theme.colorScheme.outline),
  ),
),

// AFTER:
CachedNetworkImage(
  imageUrl: article.imageUrl,
  fit: BoxFit.cover,
  memCacheWidth: 400,
  placeholder: (_, __) => Container(
    color: theme.colorScheme.surfaceContainerHighest,
  ),
  errorWidget: (_, __, ___) => Container(
    color: theme.colorScheme.surfaceContainerHighest,
    child: Icon(Icons.image, color: theme.colorScheme.outline),
  ),
),
```

**Step 2: Replace Image.network in ArticleDetailPage (_ArticleContent)**

In `lib/features/article_detail/presentation/views/article_detail_page.dart`:

Add import: `import 'package:cached_network_image/cached_network_image.dart';`

```dart
// BEFORE:
Image.network(
  article.imageUrl,
  width: double.infinity,
  fit: BoxFit.cover,
  errorBuilder: (_, __, ___) => Container(
    height: 200,
    color: theme.colorScheme.surfaceContainerHighest,
    child: Icon(Icons.image, color: theme.colorScheme.outline),
  ),
),

// AFTER:
CachedNetworkImage(
  imageUrl: article.imageUrl,
  width: double.infinity,
  fit: BoxFit.cover,
  memCacheWidth: 800,
  placeholder: (_, __) => Container(
    height: 200,
    color: theme.colorScheme.surfaceContainerHighest,
  ),
  errorWidget: (_, __, ___) => Container(
    height: 200,
    color: theme.colorScheme.surfaceContainerHighest,
    child: Icon(Icons.image, color: theme.colorScheme.outline),
  ),
),
```

**Step 3: Run all tests**

Run: `flutter test`
Expected: All tests PASS

**Step 4: Commit**

```bash
git add lib/features/news_feed/presentation/views/news_feed_page.dart lib/features/article_detail/presentation/views/article_detail_page.dart
git commit -m "feat(news_reader): replace Image.network with CachedNetworkImage for image pipeline"
```

---

## Task 5: Haptic Feedback Integration

기존 HapticService를 사용하여 북마크 토글, 댓글 작성 완료, Pull-to-Refresh에 햅틱 피드백을 추가한다.

**Files:**
- Modify: `lib/features/news_feed/presentation/views/news_feed_page.dart`
- Modify: `lib/features/article_detail/presentation/views/article_detail_page.dart`
- Modify: `lib/features/comments/presentation/views/comments_page.dart`

**Step 1: Add haptic to bookmark toggle in NewsFeedPage**

In `lib/features/news_feed/presentation/views/news_feed_page.dart`:
Add import: `import 'package:apps.news_reader/core/haptic/haptic_service.dart';`

In `_ArticleCard`, modify bookmark button's `onPressed`:
```dart
onPressed: () {
  HapticService.bookmarkToggle();
  context.read<NewsFeedBloc>().add(
        NewsFeedBookmarkToggled(article),
      );
},
```

In `_ArticleList`, modify `RefreshIndicator.onRefresh`:
```dart
onRefresh: () async {
  HapticService.pullToRefresh();
  context.read<NewsFeedBloc>().add(const NewsFeedRefreshed());
},
```

**Step 2: Add haptic to bookmark toggle in ArticleDetailPage**

In `lib/features/article_detail/presentation/views/article_detail_page.dart`:
Add import: `import 'package:apps.news_reader/core/haptic/haptic_service.dart';`

Modify bookmark button's `onPressed`:
```dart
onPressed: () {
  HapticService.bookmarkToggle();
  context
      .read<ArticleDetailBloc>()
      .add(const ArticleDetailBookmarkToggled());
},
```

**Step 3: Add haptic to comment submit in CommentsPage**

In `lib/features/comments/presentation/views/comments_page.dart`:
Add import: `import 'package:apps.news_reader/core/haptic/haptic_service.dart';`

Modify `_submit()` method to add haptic after sending:
```dart
void _submit() {
  final content = _controller.text.trim();
  if (content.isEmpty) return;

  HapticService.commentPosted();
  context.read<CommentsBloc>().add(CommentAdded(
        articleId: widget.articleId,
        authorName: _authorController.text.trim().isEmpty
            ? '익명'
            : _authorController.text.trim(),
        content: content,
      ));
  _controller.clear();
}
```

**Step 4: Run all tests**

Run: `flutter test`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add lib/features/news_feed/presentation/views/news_feed_page.dart lib/features/article_detail/presentation/views/article_detail_page.dart lib/features/comments/presentation/views/comments_page.dart
git commit -m "feat(news_reader): add haptic feedback to bookmark, comment, and refresh interactions"
```

---

## Task 6: Accessibility (Semantics)

인터랙티브 위젯에 Semantics를 추가하고, 장식용 이미지에 excludeFromSemantics를 적용한다.

**Files:**
- Modify: `lib/features/news_feed/presentation/views/news_feed_page.dart`
- Modify: `lib/features/article_detail/presentation/views/article_detail_page.dart`
- Modify: `lib/features/bookmarks/presentation/views/bookmarks_page.dart`
- Modify: `lib/features/comments/presentation/views/comments_page.dart`

**Step 1: Add Semantics to NewsFeedPage ArticleCard**

In `_ArticleCard`, wrap the entire `Card` with `Semantics`:
```dart
return Semantics(
  label: '${article.category.name} 카테고리 기사: ${article.title}',
  child: Card(
    // ... existing code
  ),
);
```

Add `excludeFromSemantics: true` to the `CachedNetworkImage`:
```dart
CachedNetworkImage(
  imageUrl: article.imageUrl,
  fit: BoxFit.cover,
  memCacheWidth: 400,
  // ... existing code
)
```
Note: CachedNetworkImage doesn't support excludeFromSemantics directly. Wrap it with `ExcludeSemantics`:
```dart
ExcludeSemantics(
  child: CachedNetworkImage(
    // ... existing code
  ),
),
```

**Step 2: Add Semantics to ArticleDetailPage bookmark/share/comment buttons**

In `lib/features/article_detail/presentation/views/article_detail_page.dart`, add tooltip to each IconButton in AppBar actions:
```dart
// Share button
IconButton(
  icon: const Icon(Icons.share_outlined),
  tooltip: '기사 공유',
  onPressed: () { ... },
),
// Comment button
IconButton(
  icon: const Icon(Icons.comment_outlined),
  tooltip: '댓글 보기',
  onPressed: () { ... },
),
// Bookmark button
IconButton(
  icon: Icon(
    state.article!.isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
  ),
  tooltip: state.article!.isBookmarked ? '북마크 제거' : '북마크 추가',
  onPressed: () { ... },
),
```

Wrap hero image with `ExcludeSemantics`:
```dart
ExcludeSemantics(
  child: ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: CachedNetworkImage(
      // ... existing code
    ),
  ),
),
```

**Step 3: Add Semantics to BookmarksPage**

In `_BookmarkCard`, wrap the Card with Semantics:
```dart
return Semantics(
  label: '북마크된 기사: ${bookmark.title}',
  child: Card(
    // ... existing code
  ),
);
```

Add tooltip to bookmark remove IconButton:
```dart
IconButton(
  icon: const Icon(Icons.bookmark_remove),
  tooltip: '북마크 제거',
  onPressed: () { ... },
  iconSize: 20,
),
```

**Step 4: Add Semantics to CommentsPage**

In `_CommentTile`, wrap with Semantics:
```dart
return Semantics(
  label: '${comment.authorName}의 댓글: ${comment.content}',
  child: Opacity(
    // ... existing code
  ),
);
```

Add tooltip to send button in `_CommentInput`:
```dart
IconButton(
  icon: const Icon(Icons.send),
  tooltip: '댓글 작성',
  onPressed: onSubmit,
),
```

**Step 5: Run all tests**

Run: `flutter test`
Expected: All tests PASS

**Step 6: Commit**

```bash
git add lib/features/
git commit -m "feat(news_reader): add accessibility semantics and tooltips to interactive widgets"
```

---

## Task 7: Article Cache SQL DataSource

article_cache 테이블을 활용하는 `SqlArticleCacheDataSource`를 구현하고 테스트한다.
기존 `MockArticleLocalDataSource`(인메모리)를 SQL로 교체할 수 있는 구조.

**Files:**
- Create: `lib/features/news_feed/external/local/sql_article_cache_data_source.dart`
- Create: `test/features/news_feed/external/local/sql_article_cache_data_source_test.dart`

**Step 1: Implement SqlArticleCacheDataSource**

```dart
// lib/features/news_feed/external/local/sql_article_cache_data_source.dart
import 'dart:convert';

import 'package:apps.news_reader/features/news_feed/data/datasources/article_local_data_source.dart';
import 'package:apps.news_reader/features/news_feed/data/dto/article_dto.dart';
import 'package:apps.news_reader/features/news_feed/data/dto/paginated_response_dto.dart';
import 'package:sqflite/sqflite.dart';

class SqlArticleCacheDataSource implements ArticleLocalDataSource {
  SqlArticleCacheDataSource(this._db);

  final Database _db;
  static const _tableName = 'article_cache';
  static const _defaultTtlMs = 300000; // 5 minutes

  @override
  Future<PaginatedResponseDto?> getCachedFeed(String cacheKey) async {
    await clearExpiredCache();

    final rows = await _db.query(
      _tableName,
      where: 'cache_key = ?',
      whereArgs: [cacheKey],
    );

    if (rows.isEmpty) return null;

    final row = rows.first;
    final cachedAt = row['cached_at'] as int;
    final ttlMs = row['ttl_ms'] as int? ?? _defaultTtlMs;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - cachedAt > ttlMs) {
      await _db.delete(_tableName, where: 'cache_key = ?', whereArgs: [cacheKey]);
      return null;
    }

    final json = jsonDecode(row['response_json'] as String) as Map<String, dynamic>;
    return PaginatedResponseDto.fromJson(json);
  }

  @override
  Future<void> cacheFeed(String cacheKey, PaginatedResponseDto response) async {
    final json = jsonEncode({
      'items': response.items.map((e) => e.toJson()).toList(),
      'nextCursor': response.nextCursor,
      'hasMore': response.hasMore,
    });

    await _db.insert(
      _tableName,
      {
        'cache_key': cacheKey,
        'response_json': json,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
        'ttl_ms': _defaultTtlMs,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> clearExpiredCache() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.rawDelete(
      'DELETE FROM $_tableName WHERE (? - cached_at) > ttl_ms',
      [now],
    );
  }
}
```

NOTE: `ArticleDto.toJson()` 메서드가 필요하다. 없으면 `lib/features/news_feed/data/dto/article_dto.dart`에 추가한다:
```dart
Map<String, dynamic> toJson() => {
  'id': id,
  'title': title,
  'summary': summary,
  'content': content,
  'imageUrl': imageUrl,
  'category': category,
  'commentCount': commentCount,
  'publishedAt': publishedAt,
  'sourceName': sourceName,
};
```

`PaginatedResponseDto`에도 필요하면 추가:
```dart
Map<String, dynamic> toJson() => {
  'items': items.map((e) => e.toJson()).toList(),
  'nextCursor': nextCursor,
  'hasMore': hasMore,
};
```

**Step 2: Write test**

```dart
// test/features/news_feed/external/local/sql_article_cache_data_source_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:apps.news_reader/features/news_feed/data/dto/article_dto.dart';
import 'package:apps.news_reader/features/news_feed/data/dto/paginated_response_dto.dart';
import 'package:apps.news_reader/features/news_feed/external/local/sql_article_cache_data_source.dart';

void main() {
  late Database db;
  late SqlArticleCacheDataSource dataSource;

  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE article_cache (
            cache_key TEXT PRIMARY KEY,
            response_json TEXT NOT NULL,
            cached_at INTEGER NOT NULL,
            ttl_ms INTEGER NOT NULL DEFAULT 300000
          )
        ''');
      },
    );
    dataSource = SqlArticleCacheDataSource(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SqlArticleCacheDataSource', () {
    final testDto = ArticleDto(
      id: 'test-1',
      title: 'Test Article',
      summary: 'Summary',
      content: 'Content',
      imageUrl: '',
      category: 'technology',
      commentCount: 0,
      publishedAt: '2025-01-01T00:00:00.000Z',
      sourceName: 'Test',
    );

    final testResponse = PaginatedResponseDto(
      items: [testDto],
      nextCursor: 'cursor-2',
      hasMore: true,
    );

    test('returns null for cache miss', () async {
      final result = await dataSource.getCachedFeed('nonexistent');
      expect(result, isNull);
    });

    test('stores and retrieves cached feed', () async {
      await dataSource.cacheFeed('feed:all:first', testResponse);
      final result = await dataSource.getCachedFeed('feed:all:first');
      expect(result, isNotNull);
      expect(result!.items.length, 1);
      expect(result.items.first.id, 'test-1');
      expect(result.nextCursor, 'cursor-2');
      expect(result.hasMore, true);
    });

    test('returns null for expired cache', () async {
      // Insert with expired timestamp
      await db.insert('article_cache', {
        'cache_key': 'expired',
        'response_json': '{"items":[],"nextCursor":null,"hasMore":false}',
        'cached_at': DateTime.now().millisecondsSinceEpoch - 400000, // 6+ minutes ago
        'ttl_ms': 300000,
      });
      final result = await dataSource.getCachedFeed('expired');
      expect(result, isNull);
    });

    test('clears expired entries', () async {
      await db.insert('article_cache', {
        'cache_key': 'old',
        'response_json': '{"items":[],"nextCursor":null,"hasMore":false}',
        'cached_at': DateTime.now().millisecondsSinceEpoch - 400000,
        'ttl_ms': 300000,
      });
      await dataSource.clearExpiredCache();
      final rows = await db.query('article_cache', where: 'cache_key = ?', whereArgs: ['old']);
      expect(rows, isEmpty);
    });

    test('overwrites existing cache with same key', () async {
      await dataSource.cacheFeed('key', testResponse);
      final updated = PaginatedResponseDto(
        items: [testDto, testDto],
        nextCursor: null,
        hasMore: false,
      );
      await dataSource.cacheFeed('key', updated);
      final result = await dataSource.getCachedFeed('key');
      expect(result!.items.length, 2);
      expect(result.hasMore, false);
    });
  });
}
```

NOTE: `sqflite_common_ffi`가 dev_dependencies에 필요하다. `pubspec.yaml`에 추가:
```yaml
dev_dependencies:
  sqflite_common_ffi: ^2.3.0
```

Run: `flutter pub get`

**Step 3: Run test**

Run: `flutter test test/features/news_feed/external/local/sql_article_cache_data_source_test.dart`
Expected: All tests PASS

**Step 4: Run all tests**

Run: `flutter test`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add lib/features/news_feed/external/local/sql_article_cache_data_source.dart lib/features/news_feed/data/dto/ test/features/news_feed/external/ pubspec.yaml pubspec.lock
git commit -m "feat(news_reader): implement SqlArticleCacheDataSource with 5-min TTL"
```

---

## Task 8: Memory Pressure Handling

App 위젯에 WidgetsBindingObserver를 추가하여 메모리 압박 시 이미지 캐시를 클리어한다.

**Files:**
- Modify: `lib/app/app.dart`

**Step 1: Add WidgetsBindingObserver to _AppView**

`_AppView`를 `StatefulWidget`으로 변경하고 `WidgetsBindingObserver`를 mixin:

```dart
class _AppView extends StatefulWidget {
  const _AppView({required this.initialLocation});

  final String initialLocation;

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.preferences.themeMode != curr.preferences.themeMode ||
          prev.preferences.locale != curr.preferences.locale,
      builder: (context, state) {
        final router = createRouter(initialLocation: widget.initialLocation);
        final locale = state.preferences.locale == AppLocale.en
            ? const Locale('en')
            : const Locale('ko');

        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: state.preferences.themeMode,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        );
      },
    );
  }
}
```

**Step 2: Run all tests**

Run: `flutter test`
Expected: All tests PASS

**Step 3: Commit**

```bash
git add lib/app/app.dart
git commit -m "feat(news_reader): add memory pressure handling to clear image cache"
```

---

## Task 9: State Restoration (PageStorageKey)

Feed, Bookmarks, Search의 스크롤 위치를 유지하기 위해 PageStorageKey를 적용한다.

**Files:**
- Modify: `lib/features/news_feed/presentation/views/news_feed_page.dart`
- Modify: `lib/features/bookmarks/presentation/views/bookmarks_page.dart`
- Modify: `lib/features/search/presentation/views/search_page.dart`

**Step 1: Add PageStorageKey to NewsFeedPage ListView**

In `_ArticleListState.build()`, add key to `ListView.builder`:
```dart
return ListView.builder(
  key: const PageStorageKey('news_feed_list'),
  controller: _scrollController,
  // ... rest unchanged
);
```

**Step 2: Add PageStorageKey to BookmarksPage ListView**

In `BookmarksPage`, add key to `ListView.builder`:
```dart
return ListView.builder(
  key: const PageStorageKey('bookmarks_list'),
  itemCount: state.bookmarks.length,
  // ... rest unchanged
);
```

**Step 3: Add PageStorageKey to SearchPage results ListView**

In search page's results ListView (search through the file for `ListView.builder` in results section), add:
```dart
key: const PageStorageKey('search_results'),
```

**Step 4: Run all tests**

Run: `flutter test`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add lib/features/news_feed/presentation/views/news_feed_page.dart lib/features/bookmarks/presentation/views/bookmarks_page.dart lib/features/search/presentation/views/search_page.dart
git commit -m "feat(news_reader): add PageStorageKey for scroll position restoration"
```

---

## Task 10: Push Notification Interface

카테고리별 토픽 구독/해제를 위한 PushNotificationService 인터페이스 + Mock 구현.

**Files:**
- Create: `lib/core/services/push_notification_service.dart`
- Create: `test/core/services/push_notification_service_test.dart`
- Modify: `lib/app/di/service_locator.dart`

**Step 1: Create interface and mock**

```dart
// lib/core/services/push_notification_service.dart
abstract class PushNotificationService {
  Future<void> initialize();
  Future<String?> getToken();
  Future<void> subscribeToTopic(String topic);
  Future<void> unsubscribeFromTopic(String topic);
  Stream<Map<String, dynamic>> get onMessage;
}

class MockPushNotificationService implements PushNotificationService {
  final Set<String> _subscribedTopics = {};

  Set<String> get subscribedTopics => Set.unmodifiable(_subscribedTopics);

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> getToken() async => 'mock-fcm-token';

  @override
  Future<void> subscribeToTopic(String topic) async {
    _subscribedTopics.add(topic);
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    _subscribedTopics.remove(topic);
  }

  @override
  Stream<Map<String, dynamic>> get onMessage => const Stream.empty();
}
```

**Step 2: Write test**

```dart
// test/core/services/push_notification_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:apps.news_reader/core/services/push_notification_service.dart';

void main() {
  group('MockPushNotificationService', () {
    late MockPushNotificationService service;

    setUp(() {
      service = MockPushNotificationService();
    });

    test('initializes without error', () async {
      await expectLater(service.initialize(), completes);
    });

    test('returns mock token', () async {
      expect(await service.getToken(), 'mock-fcm-token');
    });

    test('subscribes and unsubscribes from topics', () async {
      await service.subscribeToTopic('technology');
      await service.subscribeToTopic('science');
      expect(service.subscribedTopics, {'technology', 'science'});

      await service.unsubscribeFromTopic('technology');
      expect(service.subscribedTopics, {'science'});
    });

    test('onMessage returns empty stream', () async {
      final messages = await service.onMessage.toList();
      expect(messages, isEmpty);
    });
  });
}
```

**Step 3: Register in ServiceLocator**

Add to `lib/app/di/service_locator.dart`:
```dart
import 'package:apps.news_reader/core/services/push_notification_service.dart';

// Inside setupLocatorSingleton(), add to core services section:
..registerLazySingleton<PushNotificationService>(
  () => MockPushNotificationService(),
)
```

**Step 4: Run tests**

Run: `flutter test`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add lib/core/services/push_notification_service.dart test/core/services/push_notification_service_test.dart lib/app/di/service_locator.dart
git commit -m "feat(news_reader): add PushNotificationService interface with mock implementation"
```

---

## Task 11: Background Sync Interface

SyncBookmarks를 호출하는 BackgroundSyncService 인터페이스 + Mock 구현.

**Files:**
- Create: `lib/core/services/background_sync_service.dart`
- Create: `test/core/services/background_sync_service_test.dart`
- Modify: `lib/app/di/service_locator.dart`

**Step 1: Create interface and mock**

```dart
// lib/core/services/background_sync_service.dart
import 'package:apps.news_reader/features/bookmarks/domain/usecases/sync_bookmarks.dart';

abstract class BackgroundSyncService {
  Future<void> registerPeriodicSync({Duration interval = const Duration(minutes: 15)});
  Future<void> cancelSync();
  Future<int> executeSyncNow();
}

class MockBackgroundSyncService implements BackgroundSyncService {
  MockBackgroundSyncService({required SyncBookmarks syncBookmarks})
      : _syncBookmarks = syncBookmarks;

  final SyncBookmarks _syncBookmarks;
  bool _isRegistered = false;

  bool get isRegistered => _isRegistered;

  @override
  Future<void> registerPeriodicSync({Duration interval = const Duration(minutes: 15)}) async {
    _isRegistered = true;
  }

  @override
  Future<void> cancelSync() async {
    _isRegistered = false;
  }

  @override
  Future<int> executeSyncNow() async {
    final result = await _syncBookmarks();
    return result.dataOrNull ?? 0;
  }
}
```

**Step 2: Write test**

```dart
// test/core/services/background_sync_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/result/result.dart';
import 'package:apps.news_reader/features/bookmarks/domain/usecases/sync_bookmarks.dart';
import 'package:apps.news_reader/features/bookmarks/domain/repositories/bookmark_repository.dart';
import 'package:apps.news_reader/core/services/background_sync_service.dart';

class MockBookmarkRepository extends Mock implements BookmarkRepository {}

void main() {
  group('MockBackgroundSyncService', () {
    late MockBookmarkRepository mockRepo;
    late SyncBookmarks syncBookmarks;
    late MockBackgroundSyncService service;

    setUp(() {
      mockRepo = MockBookmarkRepository();
      syncBookmarks = SyncBookmarks(mockRepo);
      service = MockBackgroundSyncService(syncBookmarks: syncBookmarks);
    });

    test('registers and cancels periodic sync', () async {
      expect(service.isRegistered, false);
      await service.registerPeriodicSync();
      expect(service.isRegistered, true);
      await service.cancelSync();
      expect(service.isRegistered, false);
    });

    test('executeSyncNow delegates to SyncBookmarks', () async {
      when(() => mockRepo.syncBookmarks()).thenAnswer((_) async => const Success(3));
      final count = await service.executeSyncNow();
      expect(count, 3);
      verify(() => mockRepo.syncBookmarks()).called(1);
    });
  });
}
```

**Step 3: Register in ServiceLocator**

Add to `lib/app/di/service_locator.dart`:
```dart
import 'package:apps.news_reader/core/services/background_sync_service.dart';

// Inside setupLocatorSingleton(), add after use cases section:
getIt.registerLazySingleton<BackgroundSyncService>(
  () => MockBackgroundSyncService(syncBookmarks: getIt.get()),
);
```

**Step 4: Run tests**

Run: `flutter test`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add lib/core/services/background_sync_service.dart test/core/services/background_sync_service_test.dart lib/app/di/service_locator.dart
git commit -m "feat(news_reader): add BackgroundSyncService interface with mock implementation"
```

---

## Task 12: Forced Update Dialog

RemoteConfigService를 사용하여 앱 버전을 비교하고 강제/소프트 업데이트 다이얼로그를 표시한다.

**Files:**
- Create: `lib/core/update/version_checker.dart`
- Create: `lib/core/update/update_dialog.dart`
- Create: `test/core/update/version_checker_test.dart`
- Modify: `lib/main.dart`

**Step 1: Create VersionChecker**

```dart
// lib/core/update/version_checker.dart
import 'package:apps.news_reader/core/services/remote_config_service.dart';

enum UpdateRequirement { none, soft, forced }

class VersionChecker {
  const VersionChecker(this._remoteConfig);

  final RemoteConfigService _remoteConfig;

  static const String currentVersion = '1.0.0';

  UpdateRequirement check() {
    final minVersion = _remoteConfig.getString('min_version', defaultValue: '1.0.0');
    final latestVersion = _remoteConfig.getString('latest_version', defaultValue: '1.0.0');

    if (_isLessThan(currentVersion, minVersion)) {
      return UpdateRequirement.forced;
    }
    if (_isLessThan(currentVersion, latestVersion)) {
      return UpdateRequirement.soft;
    }
    return UpdateRequirement.none;
  }

  static bool _isLessThan(String a, String b) {
    final partsA = a.split('.').map(int.parse).toList();
    final partsB = b.split('.').map(int.parse).toList();
    for (var i = 0; i < 3; i++) {
      final va = i < partsA.length ? partsA[i] : 0;
      final vb = i < partsB.length ? partsB[i] : 0;
      if (va < vb) return true;
      if (va > vb) return false;
    }
    return false;
  }
}
```

**Step 2: Create UpdateDialog**

```dart
// lib/core/update/update_dialog.dart
import 'package:flutter/material.dart';
import 'version_checker.dart';

class UpdateDialog {
  static Future<void> showIfNeeded(BuildContext context, VersionChecker checker) async {
    final requirement = checker.check();

    if (requirement == UpdateRequirement.none) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: requirement != UpdateRequirement.forced,
      builder: (context) => AlertDialog(
        title: Text(
          requirement == UpdateRequirement.forced ? '업데이트 필요' : '업데이트 안내',
        ),
        content: Text(
          requirement == UpdateRequirement.forced
              ? '앱을 사용하려면 최신 버전으로 업데이트해야 합니다.'
              : '새로운 버전이 출시되었습니다. 업데이트하시겠습니까?',
        ),
        actions: [
          if (requirement == UpdateRequirement.soft)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('나중에'),
            ),
          FilledButton(
            onPressed: () {
              // In real app: launch store URL
              if (requirement != UpdateRequirement.forced) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('업데이트'),
          ),
        ],
      ),
    );
  }
}
```

**Step 3: Write VersionChecker test**

```dart
// test/core/update/version_checker_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:apps.news_reader/core/services/remote_config_service.dart';
import 'package:apps.news_reader/core/update/version_checker.dart';

void main() {
  group('VersionChecker', () {
    test('returns none when current version equals min and latest', () {
      final config = MockRemoteConfigService(overrides: {
        'min_version': '1.0.0',
        'latest_version': '1.0.0',
      });
      final checker = VersionChecker(config);
      expect(checker.check(), UpdateRequirement.none);
    });

    test('returns forced when current version is below min_version', () {
      final config = MockRemoteConfigService(overrides: {
        'min_version': '2.0.0',
        'latest_version': '2.0.0',
      });
      final checker = VersionChecker(config);
      expect(checker.check(), UpdateRequirement.forced);
    });

    test('returns soft when current version is below latest but above min', () {
      final config = MockRemoteConfigService(overrides: {
        'min_version': '1.0.0',
        'latest_version': '1.1.0',
      });
      final checker = VersionChecker(config);
      expect(checker.check(), UpdateRequirement.soft);
    });

    test('returns none when current version is above latest', () {
      final config = MockRemoteConfigService(overrides: {
        'min_version': '0.9.0',
        'latest_version': '0.9.5',
      });
      final checker = VersionChecker(config);
      expect(checker.check(), UpdateRequirement.none);
    });

    test('handles patch version comparison', () {
      final config = MockRemoteConfigService(overrides: {
        'min_version': '1.0.1',
        'latest_version': '1.0.1',
      });
      final checker = VersionChecker(config);
      expect(checker.check(), UpdateRequirement.forced);
    });
  });
}
```

**Step 4: Run tests**

Run: `flutter test test/core/update/version_checker_test.dart`
Expected: All tests PASS

**Step 5: Run all tests**

Run: `flutter test`
Expected: All tests PASS

**Step 6: Commit**

```bash
git add lib/core/update/ test/core/update/
git commit -m "feat(news_reader): add VersionChecker and Forced Update dialog"
```

---

## Task 13: Code Splitting / Deferred Loading

Onboarding과 Settings를 `deferred as`로 분리하여 초기 번들 사이즈를 줄인다.

**Files:**
- Modify: `lib/app/route/app_router.dart`

**Step 1: Apply deferred import for onboarding**

In `lib/app/route/app_router.dart`, change the onboarding import to deferred:

```dart
// BEFORE:
import 'package:apps.news_reader/features/onboarding/presentation/views/onboarding_page.dart';

// AFTER:
import 'package:apps.news_reader/features/onboarding/presentation/views/onboarding_page.dart'
    deferred as onboarding;
```

Update the onboarding route builder:
```dart
GoRoute(
  path: AppRoutes.onboarding.path,
  builder: (context, state) {
    return FutureBuilder(
      future: onboarding.loadLibrary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return onboarding.OnboardingPage(
          settingsRepository: getIt.get<SettingsRepository>(),
          onCompleted: () => context.go(AppRoutes.feed.path),
        );
      },
    );
  },
),
```

**Step 2: Apply deferred import for settings**

```dart
// BEFORE:
import 'package:apps.news_reader/features/settings/presentation/views/settings_page.dart';

// AFTER:
import 'package:apps.news_reader/features/settings/presentation/views/settings_page.dart'
    deferred as settings;
```

Update the settings route builder:
```dart
GoRoute(
  path: AppRoutes.settings.path,
  builder: (context, state) {
    return FutureBuilder(
      future: settings.loadLibrary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return BlocProvider(
          create: (_) => SettingsCubit(
            getSettings: getIt.get<GetSettings>(),
            updateSettings: getIt.get<UpdateSettings>(),
          )..loadSettings(),
          child: const settings.SettingsPage(),
        );
      },
    );
  },
),
```

**Step 3: Run all tests**

Run: `flutter test`
Expected: All tests PASS (deferred loading is transparent in test environment)

**Step 4: Commit**

```bash
git add lib/app/route/app_router.dart
git commit -m "feat(news_reader): add deferred loading for onboarding and settings screens"
```

---

## Task 14: Deep Linking Configuration

Android/iOS 플랫폼에 `news-reader://article/{id}` 딥링크 스킴을 설정한다.
GoRouter는 이미 `/article/:id` 라우트를 갖고 있으므로 플랫폼 설정만 추가.

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`

**Step 1: Add intent-filter to AndroidManifest.xml**

In `android/app/src/main/AndroidManifest.xml`, inside the `<activity>` tag for `.MainActivity`, add:

```xml
<!-- Deep Linking -->
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="news-reader" />
</intent-filter>
```

**Step 2: Add URL scheme to iOS Info.plist**

In `ios/Runner/Info.plist`, add inside the top-level `<dict>`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>news-reader</string>
        </array>
        <key>CFBundleURLName</key>
        <string>apps.news_reader</string>
    </dict>
</array>
```

**Step 3: Run all tests**

Run: `flutter test`
Expected: All tests PASS (platform config doesn't affect unit tests)

**Step 4: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist
git commit -m "feat(news_reader): add deep linking URL scheme for news-reader://article/{id}"
```

---

## Task 15: Final Verification

전체 테스트 + 정적 분석 + 빌드 검증.

**Step 1: Run all tests**

Run: `flutter test`
Expected: All tests PASS (125 existing + new tests)

**Step 2: Run static analysis**

Run: `flutter analyze`
Expected: No issues found

**Step 3: Verify the spec coverage**

체크리스트로 14개 항목 완성 여부를 확인:

- [x] A1: Bottom Navigation (ShellRoute + NavigationBar)
- [x] A2: Share Functionality (share_plus)
- [x] A3: Image Pipeline (CachedNetworkImage)
- [x] A4: Accessibility (Semantics, tooltips, ExcludeSemantics)
- [x] A5: Haptic Feedback (HapticService integration)
- [x] B1: Article Cache SQL (SqlArticleCacheDataSource)
- [x] B2: Memory Pressure Handling (WidgetsBindingObserver)
- [x] B3: Code Splitting (deferred as for onboarding/settings)
- [x] B4: State Restoration (PageStorageKey)
- [x] C1: Firebase Mock Interfaces (Analytics, Crashlytics, RemoteConfig)
- [x] C2: Forced Update (VersionChecker + UpdateDialog)
- [x] C3: Push Notification Interface (MockPushNotificationService)
- [x] C4: Background Sync Interface (MockBackgroundSyncService)
- [x] D1: Deep Linking (AndroidManifest + Info.plist)

**Step 4: Commit (if any fix-ups needed)**

```bash
git add -A
git commit -m "chore(news_reader): final verification and lint fixes"
```
