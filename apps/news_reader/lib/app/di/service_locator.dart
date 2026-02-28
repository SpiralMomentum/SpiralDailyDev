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
