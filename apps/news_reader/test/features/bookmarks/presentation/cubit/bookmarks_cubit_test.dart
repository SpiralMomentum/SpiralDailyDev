import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/result/result.dart';
import 'package:utils/result/failure.dart';
import 'package:apps.news_reader/features/bookmarks/domain/entities/bookmark.dart';
import 'package:apps.news_reader/features/bookmarks/domain/usecases/get_bookmarks.dart';
import 'package:apps.news_reader/features/bookmarks/domain/usecases/toggle_bookmark.dart';
import 'package:apps.news_reader/features/news_feed/domain/entities/article.dart';
import 'package:apps.news_reader/features/bookmarks/presentation/cubit/bookmarks_cubit.dart';
import 'package:apps.news_reader/features/bookmarks/presentation/cubit/bookmarks_state.dart';

class MockGetBookmarks extends Mock implements GetBookmarks {}

class MockToggleBookmark extends Mock implements ToggleBookmark {}

void main() {
  late MockGetBookmarks getBookmarks;
  late MockToggleBookmark toggleBookmark;

  final tBookmark = Bookmark(
    articleId: 'art-1',
    title: 'Saved Article',
    summary: 'Summary',
    content: 'Content',
    imageUrl: 'url',
    category: 'technology',
    savedAt: DateTime(2024, 1, 1),
    syncStatus: SyncStatus.synced,
  );

  setUp(() {
    getBookmarks = MockGetBookmarks();
    toggleBookmark = MockToggleBookmark();
  });

  setUpAll(() {
    registerFallbackValue(Article(
      id: '',
      title: '',
      summary: '',
      content: '',
      imageUrl: '',
      category: ArticleCategory.technology,
      isBookmarked: false,
      commentCount: 0,
      publishedAt: DateTime(2024),
      sourceName: '',
    ));
  });

  BookmarksCubit buildCubit() => BookmarksCubit(
        getBookmarks: getBookmarks,
        toggleBookmark: toggleBookmark,
      );

  group('BookmarksCubit', () {
    blocTest<BookmarksCubit, BookmarksState>(
      'emits [loading, loaded] on successful loadBookmarks',
      build: () {
        when(() => getBookmarks())
            .thenAnswer((_) async => Success([tBookmark]));
        return buildCubit();
      },
      act: (cubit) => cubit.loadBookmarks(),
      expect: () => [
        const BookmarksState(status: BookmarksStatus.loading),
        BookmarksState(
          status: BookmarksStatus.loaded,
          bookmarks: [tBookmark],
        ),
      ],
    );

    blocTest<BookmarksCubit, BookmarksState>(
      'emits [loading, error] on failed loadBookmarks',
      build: () {
        when(() => getBookmarks()).thenAnswer(
          (_) async =>
              ErrorResult(const LocalStorageFailure(message: 'DB error')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.loadBookmarks(),
      expect: () => [
        const BookmarksState(status: BookmarksStatus.loading),
        const BookmarksState(
          status: BookmarksStatus.error,
          errorMessage: 'DB error',
        ),
      ],
    );

    blocTest<BookmarksCubit, BookmarksState>(
      'removes bookmark and reloads list on success',
      build: () {
        when(() => toggleBookmark(any()))
            .thenAnswer((_) async => const Success(false));
        when(() => getBookmarks())
            .thenAnswer((_) async => const Success(<Bookmark>[]));
        return buildCubit();
      },
      act: (cubit) => cubit.removeBookmark(tBookmark),
      expect: () => [
        const BookmarksState(status: BookmarksStatus.loading),
        const BookmarksState(
          status: BookmarksStatus.loaded,
          bookmarks: [],
        ),
      ],
    );

    blocTest<BookmarksCubit, BookmarksState>(
      'does not reload when removeBookmark toggle fails',
      build: () {
        when(() => toggleBookmark(any())).thenAnswer(
          (_) async =>
              ErrorResult(const NetworkFailure(message: 'Network error')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.removeBookmark(tBookmark),
      expect: () => <BookmarksState>[],
      verify: (_) {
        verifyNever(() => getBookmarks());
      },
    );

    blocTest<BookmarksCubit, BookmarksState>(
      'emits loaded with empty list when no bookmarks',
      build: () {
        when(() => getBookmarks())
            .thenAnswer((_) async => const Success(<Bookmark>[]));
        return buildCubit();
      },
      act: (cubit) => cubit.loadBookmarks(),
      expect: () => [
        const BookmarksState(status: BookmarksStatus.loading),
        const BookmarksState(
          status: BookmarksStatus.loaded,
          bookmarks: [],
        ),
      ],
    );

    blocTest<BookmarksCubit, BookmarksState>(
      'passes correct Article to toggleBookmark when removing',
      build: () {
        when(() => toggleBookmark(any()))
            .thenAnswer((_) async => const Success(false));
        when(() => getBookmarks())
            .thenAnswer((_) async => const Success(<Bookmark>[]));
        return buildCubit();
      },
      act: (cubit) => cubit.removeBookmark(tBookmark),
      verify: (_) {
        final captured = verify(() => toggleBookmark(captureAny()))
            .captured
            .single as Article;
        expect(captured.id, equals('art-1'));
        expect(captured.title, equals('Saved Article'));
        expect(captured.isBookmarked, isTrue);
        expect(captured.category, equals(ArticleCategory.technology));
      },
    );
  });
}
