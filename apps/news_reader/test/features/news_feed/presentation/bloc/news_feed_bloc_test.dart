import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/result/result.dart';
import 'package:utils/result/failure.dart';
import 'package:apps.news_reader/features/news_feed/domain/entities/article.dart';
import 'package:apps.news_reader/features/news_feed/domain/entities/paginated_articles.dart';
import 'package:apps.news_reader/features/news_feed/domain/usecases/get_article_feed.dart';
import 'package:apps.news_reader/features/bookmarks/domain/usecases/toggle_bookmark.dart';
import 'package:apps.news_reader/features/news_feed/presentation/bloc/news_feed_bloc.dart';
import 'package:apps.news_reader/features/news_feed/presentation/bloc/news_feed_event.dart';
import 'package:apps.news_reader/features/news_feed/presentation/bloc/news_feed_state.dart';

class MockGetArticleFeed extends Mock implements GetArticleFeed {}

class MockToggleBookmark extends Mock implements ToggleBookmark {}

void main() {
  late MockGetArticleFeed getArticleFeed;
  late MockToggleBookmark toggleBookmark;

  final tArticle = Article(
    id: '1',
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

  final tPaginated = PaginatedArticles(
    articles: [tArticle],
    nextCursor: '1',
    hasMore: true,
  );

  setUp(() {
    getArticleFeed = MockGetArticleFeed();
    toggleBookmark = MockToggleBookmark();
  });

  setUpAll(() {
    registerFallbackValue(ArticleCategory.technology);
    registerFallbackValue(tArticle);
  });

  NewsFeedBloc buildBloc() => NewsFeedBloc(
        getArticleFeed: getArticleFeed,
        toggleBookmark: toggleBookmark,
      );

  group('NewsFeedBloc', () {
    blocTest<NewsFeedBloc, NewsFeedState>(
      'emits [loading, loaded] when NewsFeedStarted succeeds',
      build: () {
        when(() => getArticleFeed(
              category: any(named: 'category'),
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => Success(tPaginated));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const NewsFeedStarted()),
      expect: () => [
        const NewsFeedState(status: NewsFeedStatus.loading),
        NewsFeedState(
          status: NewsFeedStatus.loaded,
          articles: [tArticle],
          nextCursor: '1',
          hasMore: true,
        ),
      ],
    );

    blocTest<NewsFeedBloc, NewsFeedState>(
      'emits [loading, error] when NewsFeedStarted fails',
      build: () {
        when(() => getArticleFeed(
              category: any(named: 'category'),
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            )).thenAnswer(
          (_) async =>
              ErrorResult(const NetworkFailure(message: 'No connection')),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const NewsFeedStarted()),
      expect: () => [
        const NewsFeedState(status: NewsFeedStatus.loading),
        const NewsFeedState(
          status: NewsFeedStatus.error,
          errorMessage: 'No connection',
        ),
      ],
    );

    blocTest<NewsFeedBloc, NewsFeedState>(
      'appends articles on NextPageRequested',
      build: () {
        when(() => getArticleFeed(
              category: any(named: 'category'),
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => Success(PaginatedArticles(
              articles: [tArticle.copyWith(id: '2')],
              nextCursor: '2',
              hasMore: false,
            )));
        return buildBloc();
      },
      seed: () => NewsFeedState(
        status: NewsFeedStatus.loaded,
        articles: [tArticle],
        nextCursor: '1',
        hasMore: true,
      ),
      act: (bloc) => bloc.add(const NewsFeedNextPageRequested()),
      expect: () => [
        NewsFeedState(
          status: NewsFeedStatus.loaded,
          articles: [tArticle],
          nextCursor: '1',
          hasMore: true,
          isLoadingMore: true,
        ),
        NewsFeedState(
          status: NewsFeedStatus.loaded,
          articles: [tArticle, tArticle.copyWith(id: '2')],
          nextCursor: '2',
          hasMore: false,
        ),
      ],
    );

    blocTest<NewsFeedBloc, NewsFeedState>(
      'does not fetch when hasMore is false',
      build: buildBloc,
      seed: () => const NewsFeedState(
        status: NewsFeedStatus.loaded,
        hasMore: false,
      ),
      act: (bloc) => bloc.add(const NewsFeedNextPageRequested()),
      expect: () => <NewsFeedState>[],
      verify: (_) {
        verifyNever(() => getArticleFeed(
              category: any(named: 'category'),
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            ));
      },
    );

    blocTest<NewsFeedBloc, NewsFeedState>(
      'resets and reloads on CategoryChanged',
      build: () {
        when(() => getArticleFeed(
              category: any(named: 'category'),
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => Success(tPaginated));
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const NewsFeedCategoryChanged(ArticleCategory.science)),
      expect: () => [
        const NewsFeedState(
          status: NewsFeedStatus.loading,
          selectedCategory: ArticleCategory.science,
        ),
        NewsFeedState(
          status: NewsFeedStatus.loaded,
          selectedCategory: ArticleCategory.science,
          articles: [tArticle],
          nextCursor: '1',
          hasMore: true,
        ),
      ],
    );

    blocTest<NewsFeedBloc, NewsFeedState>(
      'updates article bookmark status on BookmarkToggled success',
      build: () {
        when(() => toggleBookmark(any()))
            .thenAnswer((_) async => const Success(true));
        return buildBloc();
      },
      seed: () => NewsFeedState(
        status: NewsFeedStatus.loaded,
        articles: [tArticle],
      ),
      act: (bloc) => bloc.add(NewsFeedBookmarkToggled(tArticle)),
      expect: () => [
        NewsFeedState(
          status: NewsFeedStatus.loaded,
          articles: [tArticle.copyWith(isBookmarked: true)],
        ),
      ],
    );

    blocTest<NewsFeedBloc, NewsFeedState>(
      'does not emit when BookmarkToggled fails',
      build: () {
        when(() => toggleBookmark(any())).thenAnswer(
          (_) async =>
              ErrorResult(const NetworkFailure(message: 'Bookmark error')),
        );
        return buildBloc();
      },
      seed: () => NewsFeedState(
        status: NewsFeedStatus.loaded,
        articles: [tArticle],
      ),
      act: (bloc) => bloc.add(NewsFeedBookmarkToggled(tArticle)),
      expect: () => <NewsFeedState>[],
    );

    blocTest<NewsFeedBloc, NewsFeedState>(
      'does not fetch next page when already loading more',
      build: buildBloc,
      seed: () => const NewsFeedState(
        status: NewsFeedStatus.loaded,
        hasMore: true,
        isLoadingMore: true,
      ),
      act: (bloc) => bloc.add(const NewsFeedNextPageRequested()),
      expect: () => <NewsFeedState>[],
      verify: (_) {
        verifyNever(() => getArticleFeed(
              category: any(named: 'category'),
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            ));
      },
    );

    blocTest<NewsFeedBloc, NewsFeedState>(
      'refreshes feed without loading status on NewsFeedRefreshed',
      build: () {
        when(() => getArticleFeed(
              category: any(named: 'category'),
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => Success(tPaginated));
        return buildBloc();
      },
      seed: () => NewsFeedState(
        status: NewsFeedStatus.loaded,
        articles: [tArticle.copyWith(id: 'old')],
        nextCursor: 'old-cursor',
        hasMore: true,
      ),
      act: (bloc) => bloc.add(const NewsFeedRefreshed()),
      expect: () => [
        NewsFeedState(
          status: NewsFeedStatus.loaded,
          articles: [tArticle],
          nextCursor: '1',
          hasMore: true,
        ),
      ],
    );
  });
}
