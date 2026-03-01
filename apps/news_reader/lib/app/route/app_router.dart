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
import 'package:apps.news_reader/features/onboarding/presentation/views/onboarding_page.dart'
    deferred as onboarding;
import 'package:apps.news_reader/features/search/domain/repositories/search_repository.dart';
import 'package:apps.news_reader/features/search/domain/usecases/search_articles.dart';
import 'package:apps.news_reader/features/search/presentation/cubit/search_cubit.dart';
import 'package:apps.news_reader/features/search/presentation/views/search_page.dart';
import 'package:apps.news_reader/features/settings/domain/repositories/settings_repository.dart';
import 'package:apps.news_reader/features/settings/domain/usecases/get_settings.dart';
import 'package:apps.news_reader/features/settings/domain/usecases/update_settings.dart';
import 'package:apps.news_reader/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:apps.news_reader/features/settings/presentation/views/settings_page.dart'
    deferred as settings;
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
                    child: settings.SettingsPage(),
                  );
                },
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
