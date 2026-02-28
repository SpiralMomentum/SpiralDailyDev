import 'package:apps.news_reader/app/di/service_locator.dart';
import 'package:apps.news_reader/app/route/app_routes.dart';
import 'package:apps.news_reader/features/article_detail/domain/usecases/get_article_detail.dart';
import 'package:apps.news_reader/features/bookmarks/domain/usecases/get_bookmarks.dart';
import 'package:apps.news_reader/features/bookmarks/domain/usecases/toggle_bookmark.dart';
import 'package:apps.news_reader/features/news_feed/domain/usecases/get_article_feed.dart';
import 'package:apps.news_reader/features/news_feed/presentation/bloc/news_feed_bloc.dart';
import 'package:apps.news_reader/features/news_feed/presentation/bloc/news_feed_event.dart';
import 'package:apps.news_reader/features/news_feed/presentation/views/news_feed_page.dart';
import 'package:apps.news_reader/features/article_detail/presentation/bloc/article_detail_bloc.dart';
import 'package:apps.news_reader/features/article_detail/presentation/bloc/article_detail_event.dart';
import 'package:apps.news_reader/features/article_detail/presentation/views/article_detail_page.dart';
import 'package:apps.news_reader/features/bookmarks/presentation/cubit/bookmarks_cubit.dart';
import 'package:apps.news_reader/features/bookmarks/presentation/views/bookmarks_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: AppRoutes.feed.path,
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
    ],
  );
}
