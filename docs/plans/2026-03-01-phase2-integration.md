# Phase 2 Integration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Wire all existing Phase 2 feature code (comments, search, settings, onboarding) into the app so every screen is reachable and functional with mock data.

**Architecture:** Extend ServiceLocator with new registrations, add GoRouter routes for 4 missing screens, wrap App with global SettingsCubit for theme/locale binding, add conditional onboarding-first flow.

**Tech Stack:** Flutter, flutter_bloc, get_it, go_router, equatable, sqflite

**Worktree:** `/Users/gyubinhwang/AndroidStudioProjects/spiral_dev/.worktrees/news-reader/`
**App root:** `apps/news_reader/`

---

### Task 1: Extend ServiceLocator with Comments, Search, Settings registrations

**Files:**
- Modify: `lib/app/di/service_locator.dart`

**Step 1: Write the updated ServiceLocator**

Replace the full file with:

```dart
import 'package:apps.news_reader/features/bookmarks/data/datasources/bookmark_local_data_source.dart';
import 'package:apps.news_reader/features/bookmarks/data/repositories/bookmark_repository_impl.dart';
import 'package:apps.news_reader/features/bookmarks/domain/repositories/bookmark_repository.dart';
import 'package:apps.news_reader/features/bookmarks/domain/usecases/get_bookmarks.dart';
import 'package:apps.news_reader/features/bookmarks/domain/usecases/sync_bookmarks.dart';
import 'package:apps.news_reader/features/bookmarks/domain/usecases/toggle_bookmark.dart';
import 'package:apps.news_reader/features/bookmarks/external/local/in_memory_bookmark_local_data_source.dart';
import 'package:apps.news_reader/features/comments/data/datasources/comment_data_source.dart';
import 'package:apps.news_reader/features/comments/data/repositories/comment_repository_impl.dart';
import 'package:apps.news_reader/features/comments/domain/repositories/comment_repository.dart';
import 'package:apps.news_reader/features/comments/domain/usecases/add_comment.dart';
import 'package:apps.news_reader/features/comments/domain/usecases/watch_comments.dart';
import 'package:apps.news_reader/features/comments/external/mock/mock_comment_data_source.dart';
import 'package:apps.news_reader/features/news_feed/data/datasources/article_local_data_source.dart';
import 'package:apps.news_reader/features/news_feed/data/datasources/article_remote_data_source.dart';
import 'package:apps.news_reader/features/news_feed/data/repositories/article_repository_impl.dart';
import 'package:apps.news_reader/features/news_feed/domain/repositories/article_repository.dart';
import 'package:apps.news_reader/features/article_detail/domain/usecases/get_article_detail.dart';
import 'package:apps.news_reader/features/news_feed/domain/usecases/get_article_feed.dart';
import 'package:apps.news_reader/features/news_feed/external/mock/mock_article_local_data_source.dart';
import 'package:apps.news_reader/features/news_feed/external/mock/mock_article_remote_data_source.dart';
import 'package:apps.news_reader/features/search/data/datasources/search_history_data_source.dart';
import 'package:apps.news_reader/features/search/data/repositories/search_repository_impl.dart';
import 'package:apps.news_reader/features/search/domain/repositories/search_repository.dart';
import 'package:apps.news_reader/features/search/domain/usecases/search_articles.dart';
import 'package:apps.news_reader/features/search/external/local/in_memory_search_history_data_source.dart';
import 'package:apps.news_reader/features/search/external/mock/mock_search_remote_data_source.dart';
import 'package:apps.news_reader/features/settings/data/datasources/settings_data_source.dart';
import 'package:apps.news_reader/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:apps.news_reader/features/settings/domain/repositories/settings_repository.dart';
import 'package:apps.news_reader/features/settings/domain/usecases/get_settings.dart';
import 'package:apps.news_reader/features/settings/domain/usecases/update_settings.dart';
import 'package:apps.news_reader/features/settings/external/local/in_memory_settings_data_source.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

class ServiceLocator {
  static Future<void> setupLocatorSingleton() async {
    // External (Data Sources)
    getIt
      ..registerLazySingleton<ArticleRemoteDataSource>(
        () => MockArticleRemoteDataSource(),
      )
      ..registerLazySingleton<ArticleLocalDataSource>(
        () => MockArticleLocalDataSource(),
      )
      ..registerLazySingleton<BookmarkLocalDataSource>(
        () => InMemoryBookmarkLocalDataSource(),
      )
      ..registerLazySingleton<CommentDataSource>(
        () => MockCommentDataSource(),
      )
      ..registerLazySingleton<SearchHistoryDataSource>(
        () => InMemorySearchHistoryDataSource(),
      )
      ..registerLazySingleton<SettingsDataSource>(
        () => InMemorySettingsDataSource(),
      );

    // Search uses its own remote data source (separate mock data)
    getIt.registerLazySingleton<MockSearchRemoteDataSource>(
      () => MockSearchRemoteDataSource(),
    );

    // Data (Repositories)
    getIt
      ..registerLazySingleton<ArticleRepository>(
        () => ArticleRepositoryImpl(
          remoteDataSource: getIt.get(),
          localDataSource: getIt.get(),
        ),
      )
      ..registerLazySingleton<BookmarkRepository>(
        () => BookmarkRepositoryImpl(localDataSource: getIt.get()),
      )
      ..registerLazySingleton<CommentRepository>(
        () => CommentRepositoryImpl(dataSource: getIt.get()),
      )
      ..registerLazySingleton<SearchRepository>(
        () => SearchRepositoryImpl(
          remoteDataSource: getIt.get<MockSearchRemoteDataSource>(),
          historyDataSource: getIt.get(),
        ),
      )
      ..registerLazySingleton<SettingsRepository>(
        () => SettingsRepositoryImpl(dataSource: getIt.get()),
      );

    // Domain (Use Cases)
    getIt
      ..registerFactory<GetArticleFeed>(
        () => GetArticleFeed(getIt.get()),
      )
      ..registerFactory<GetArticleDetail>(
        () => GetArticleDetail(getIt.get()),
      )
      ..registerFactory<ToggleBookmark>(
        () => ToggleBookmark(getIt.get()),
      )
      ..registerFactory<GetBookmarks>(
        () => GetBookmarks(getIt.get()),
      )
      ..registerFactory<SyncBookmarks>(
        () => SyncBookmarks(getIt.get()),
      )
      ..registerFactory<WatchComments>(
        () => WatchComments(getIt.get()),
      )
      ..registerFactory<AddComment>(
        () => AddComment(getIt.get()),
      )
      ..registerFactory<SearchArticles>(
        () => SearchArticles(getIt.get()),
      )
      ..registerFactory<GetSettings>(
        () => GetSettings(getIt.get()),
      )
      ..registerFactory<UpdateSettings>(
        () => UpdateSettings(getIt.get()),
      );
  }
}
```

**Step 2: Run tests to verify no regressions**

Run: `cd /Users/gyubinhwang/AndroidStudioProjects/spiral_dev/.worktrees/news-reader/apps/news_reader && flutter test`
Expected: All 122 tests pass.

**Step 3: Commit**

```bash
git add apps/news_reader/lib/app/di/service_locator.dart
git commit -m "feat(news_reader): register comments, search, settings in ServiceLocator"
```

---

### Task 2: Add GoRouter routes for comments, search, settings, onboarding

**Files:**
- Modify: `lib/app/route/app_router.dart`

**Step 1: Write the updated router**

Replace the full file. Key additions:
- `createRouter` takes `initialLocation` parameter (for onboarding logic)
- 4 new routes: onboarding, comments, search, settings

```dart
import 'package:apps.news_reader/app/di/service_locator.dart';
import 'package:apps.news_reader/app/route/app_routes.dart';
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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
  );
}
```

**Step 2: Run tests to verify no regressions**

Run: `cd /Users/gyubinhwang/AndroidStudioProjects/spiral_dev/.worktrees/news-reader/apps/news_reader && flutter test`
Expected: All tests pass.

**Step 3: Commit**

```bash
git add apps/news_reader/lib/app/route/app_router.dart
git commit -m "feat(news_reader): add routes for onboarding, comments, search, settings"
```

---

### Task 3: Wrap App with global SettingsCubit and onboarding flow

**Files:**
- Modify: `lib/app/app.dart`
- Modify: `lib/main.dart`

**Step 1: Update App to use SettingsCubit for theme/locale**

Replace `lib/app/app.dart`:

```dart
import 'package:apps.news_reader/app/di/service_locator.dart';
import 'package:apps.news_reader/app/route/app_router.dart';
import 'package:apps.news_reader/features/settings/domain/entities/user_preferences.dart';
import 'package:apps.news_reader/features/settings/domain/usecases/get_settings.dart';
import 'package:apps.news_reader/features/settings/domain/usecases/update_settings.dart';
import 'package:apps.news_reader/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:apps.news_reader/features/settings/presentation/cubit/settings_state.dart';
import 'package:apps.news_reader/l10n/app_localizations.dart';
import 'package:apps.news_reader/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class App extends StatelessWidget {
  const App({super.key, required this.initialLocation});

  final String initialLocation;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsCubit(
        getSettings: getIt.get<GetSettings>(),
        updateSettings: getIt.get<UpdateSettings>(),
      )..loadSettings(),
      child: _AppView(initialLocation: initialLocation),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView({required this.initialLocation});

  final String initialLocation;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.preferences.themeMode != curr.preferences.themeMode ||
          prev.preferences.locale != curr.preferences.locale,
      builder: (context, state) {
        final router = createRouter(initialLocation: initialLocation);
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

**Step 2: Update main.dart to check onboarding status**

Replace `lib/main.dart`:

```dart
import 'dart:async';

import 'package:apps.news_reader/app/app.dart';
import 'package:apps.news_reader/app/di/service_locator.dart';
import 'package:apps.news_reader/app/route/app_routes.dart';
import 'package:apps.news_reader/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:utils/result/result.dart';

void main() {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
    };

    await ServiceLocator.setupLocatorSingleton();

    final settingsRepo = getIt.get<SettingsRepository>();
    final result = await settingsRepo.isOnboardingCompleted();

    final onboardingDone = switch (result) {
      Success(data: final completed) => completed,
      ErrorResult() => false,
    };

    final initialLocation = onboardingDone
        ? AppRoutes.feed.path
        : AppRoutes.onboarding.path;

    runApp(App(initialLocation: initialLocation));
  }, (error, stack) {
    debugPrint('Unhandled error: $error\n$stack');
  });
}
```

**Step 3: Run tests to verify no regressions**

Run: `cd /Users/gyubinhwang/AndroidStudioProjects/spiral_dev/.worktrees/news-reader/apps/news_reader && flutter test`
Expected: All tests pass.

**Step 4: Commit**

```bash
git add apps/news_reader/lib/app/app.dart apps/news_reader/lib/main.dart
git commit -m "feat(news_reader): add global SettingsCubit and onboarding-first flow"
```

---

### Task 4: Add navigation links (search, settings icons in feed; comments button in detail)

**Files:**
- Modify: `lib/features/news_feed/presentation/views/news_feed_page.dart`
- Modify: `lib/features/article_detail/presentation/views/article_detail_page.dart`

**Step 1: Add search and settings icons to NewsFeedPage AppBar**

In `news_feed_page.dart`, find the `actions` list in AppBar and add search + settings icons:

```dart
// Replace the existing actions list:
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
```

Also add the import for AppRoutes at the top if not present:
```dart
import 'package:apps.news_reader/app/route/app_routes.dart';
```

**Step 2: Add comments button to ArticleDetailPage**

In `article_detail_page.dart`, add a comments action in the AppBar actions, before the bookmark icon:

```dart
// Add to the actions list, before the bookmark IconButton:
IconButton(
  icon: const Icon(Icons.comment_outlined),
  onPressed: () {
    context.push('/article/${state.article!.id}/comments');
  },
),
```

Also add go_router import if not present:
```dart
import 'package:go_router/go_router.dart';
```

**Step 3: Run tests to verify no regressions**

Run: `cd /Users/gyubinhwang/AndroidStudioProjects/spiral_dev/.worktrees/news-reader/apps/news_reader && flutter test`
Expected: All tests pass.

**Step 4: Commit**

```bash
git add apps/news_reader/lib/features/news_feed/presentation/views/news_feed_page.dart apps/news_reader/lib/features/article_detail/presentation/views/article_detail_page.dart
git commit -m "feat(news_reader): add navigation links for search, settings, comments"
```

---

### Task 5: Write integration test for new routes

**Files:**
- Create: `test/app/route/app_router_test.dart`

**Step 1: Write router integration test**

```dart
import 'package:apps.news_reader/app/di/service_locator.dart';
import 'package:apps.news_reader/app/route/app_router.dart';
import 'package:apps.news_reader/app/route/app_routes.dart';
import 'package:flutter/material.dart';
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

**Step 2: Run the new test**

Run: `cd /Users/gyubinhwang/AndroidStudioProjects/spiral_dev/.worktrees/news-reader/apps/news_reader && flutter test test/app/route/app_router_test.dart -v`
Expected: All tests pass.

**Step 3: Run full test suite**

Run: `cd /Users/gyubinhwang/AndroidStudioProjects/spiral_dev/.worktrees/news-reader/apps/news_reader && flutter test`
Expected: All tests pass (122 + new tests).

**Step 4: Commit**

```bash
git add apps/news_reader/test/app/route/app_router_test.dart
git commit -m "test(news_reader): add router integration tests for all routes"
```

---

### Task 6: Final verification and stage all untracked Phase 2 files

**Step 1: Run flutter analyze**

Run: `cd /Users/gyubinhwang/AndroidStudioProjects/spiral_dev/.worktrees/news-reader/apps/news_reader && flutter analyze`
Expected: No issues found.

**Step 2: Run full test suite**

Run: `cd /Users/gyubinhwang/AndroidStudioProjects/spiral_dev/.worktrees/news-reader/apps/news_reader && flutter test`
Expected: All tests pass.

**Step 3: Commit all remaining untracked Phase 2 files**

Stage and commit all previously untracked feature code, core infra, and tests that were written in Phase 2 but never committed:

```bash
cd /Users/gyubinhwang/AndroidStudioProjects/spiral_dev/.worktrees/news-reader
git add apps/news_reader/lib/core/ apps/news_reader/lib/features/comments/ apps/news_reader/lib/features/onboarding/ apps/news_reader/lib/features/search/ apps/news_reader/lib/features/settings/ apps/news_reader/lib/features/bookmarks/domain/usecases/sync_bookmarks.dart apps/news_reader/lib/features/bookmarks/external/local/sql_bookmark_local_data_source.dart apps/news_reader/test/core/ apps/news_reader/test/features/bookmarks/ apps/news_reader/test/features/comments/ apps/news_reader/test/features/onboarding/ apps/news_reader/test/features/search/ apps/news_reader/test/features/settings/ apps/news_reader/lib/l10n/ apps/news_reader/pubspec.yaml apps/news_reader/.metadata
git commit -m "feat(news_reader): implement Phase 2 — comments, search, settings, onboarding, core infra

Adds:
- Comments: real-time stream with optimistic updates
- Search: debounced query with pagination and history
- Settings: theme, locale, notifications, categories
- Onboarding: 3-step flow with category selection
- Core: circuit breaker, resilient executor, feature flags, SDUI renderer, haptic, adaptive layout
- SQLite bookmark data source and sync usecase
- Full test coverage for all new features"
```

**Step 4: Verify clean status**

Run: `cd /Users/gyubinhwang/AndroidStudioProjects/spiral_dev/.worktrees/news-reader && git status`
Expected: Working tree clean (or only unrelated files remain).
