import 'package:apps.news_reader/features/bookmarks/data/datasources/bookmark_local_data_source.dart';
import 'package:apps.news_reader/features/bookmarks/data/repositories/bookmark_repository_impl.dart';
import 'package:apps.news_reader/features/bookmarks/domain/repositories/bookmark_repository.dart';
import 'package:apps.news_reader/features/bookmarks/domain/usecases/get_bookmarks.dart';
import 'package:apps.news_reader/features/bookmarks/domain/usecases/toggle_bookmark.dart';
import 'package:apps.news_reader/features/bookmarks/external/local/in_memory_bookmark_local_data_source.dart';
import 'package:apps.news_reader/features/news_feed/data/datasources/article_local_data_source.dart';
import 'package:apps.news_reader/features/news_feed/data/datasources/article_remote_data_source.dart';
import 'package:apps.news_reader/features/news_feed/data/repositories/article_repository_impl.dart';
import 'package:apps.news_reader/features/news_feed/domain/repositories/article_repository.dart';
import 'package:apps.news_reader/features/article_detail/domain/usecases/get_article_detail.dart';
import 'package:apps.news_reader/features/news_feed/domain/usecases/get_article_feed.dart';
import 'package:apps.news_reader/features/news_feed/external/mock/mock_article_local_data_source.dart';
import 'package:apps.news_reader/features/news_feed/external/mock/mock_article_remote_data_source.dart';
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
      );
  }
}
