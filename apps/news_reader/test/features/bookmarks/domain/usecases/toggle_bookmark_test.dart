import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/result/result.dart';
import 'package:utils/result/failure.dart';
import 'package:apps.news_reader/features/news_feed/domain/entities/article.dart';
import 'package:apps.news_reader/features/bookmarks/domain/entities/bookmark.dart';
import 'package:apps.news_reader/features/bookmarks/domain/repositories/bookmark_repository.dart';
import 'package:apps.news_reader/features/bookmarks/domain/usecases/toggle_bookmark.dart';

class MockBookmarkRepository extends Mock implements BookmarkRepository {}

void main() {
  late ToggleBookmark usecase;
  late MockBookmarkRepository repository;

  setUp(() {
    repository = MockBookmarkRepository();
    usecase = ToggleBookmark(repository);
  });

  setUpAll(() {
    registerFallbackValue(Bookmark(
      articleId: '',
      title: '',
      summary: '',
      content: '',
      imageUrl: '',
      category: '',
      savedAt: DateTime(2024),
      syncStatus: SyncStatus.synced,
    ));
  });

  final tArticle = Article(
    id: 'art-1',
    title: 'Test',
    summary: 'Summary',
    content: 'Content',
    imageUrl: 'url',
    category: ArticleCategory.technology,
    isBookmarked: false,
    commentCount: 0,
    publishedAt: DateTime(2024, 1, 1),
    sourceName: 'Source',
  );

  group('ToggleBookmark', () {
    test('removes bookmark when already bookmarked', () async {
      when(() => repository.isBookmarked('art-1'))
          .thenAnswer((_) async => const Success(true));
      when(() => repository.removeBookmark('art-1'))
          .thenAnswer((_) async => const Success(null));

      final result = await usecase(tArticle);

      expect(result, isA<Success<bool>>());
      final success = result as Success<bool>;
      expect(success.data, false);
      verify(() => repository.removeBookmark('art-1')).called(1);
    });

    test('adds bookmark when not bookmarked', () async {
      when(() => repository.isBookmarked('art-1'))
          .thenAnswer((_) async => const Success(false));
      when(() => repository.addBookmark(any()))
          .thenAnswer((_) async => Success(Bookmark(
                articleId: 'art-1',
                title: 'Test',
                summary: 'Summary',
                content: 'Content',
                imageUrl: 'url',
                category: 'technology',
                savedAt: DateTime(2024),
                syncStatus: SyncStatus.pendingUpload,
              )));

      final result = await usecase(tArticle);

      expect(result, isA<Success<bool>>());
      final success = result as Success<bool>;
      expect(success.data, true);
      verify(() => repository.addBookmark(any())).called(1);
    });

    test('returns ErrorResult when isBookmarked fails', () async {
      when(() => repository.isBookmarked('art-1')).thenAnswer(
        (_) async => ErrorResult(LocalStorageFailure(message: 'DB error')),
      );

      final result = await usecase(tArticle);

      expect(result, isA<ErrorResult<bool>>());
    });

    test('returns ErrorResult when removeBookmark fails', () async {
      when(() => repository.isBookmarked('art-1'))
          .thenAnswer((_) async => const Success(true));
      when(() => repository.removeBookmark('art-1')).thenAnswer(
        (_) async => ErrorResult(LocalStorageFailure(message: 'fail')),
      );

      final result = await usecase(tArticle);

      expect(result, isA<ErrorResult<bool>>());
    });
  });
}
