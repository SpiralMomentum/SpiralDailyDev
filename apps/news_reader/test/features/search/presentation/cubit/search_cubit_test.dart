import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/result/result.dart';
import 'package:utils/result/failure.dart';

import 'package:apps.news_reader/features/news_feed/domain/entities/article.dart';
import 'package:apps.news_reader/features/news_feed/domain/entities/paginated_articles.dart';
import 'package:apps.news_reader/features/search/domain/repositories/search_repository.dart';
import 'package:apps.news_reader/features/search/domain/usecases/search_articles.dart';
import 'package:apps.news_reader/features/search/presentation/cubit/search_cubit.dart';
import 'package:apps.news_reader/features/search/presentation/cubit/search_state.dart';

class MockSearchArticles extends Mock implements SearchArticles {}

class MockSearchRepository extends Mock implements SearchRepository {}

void main() {
  late SearchCubit cubit;
  late MockSearchArticles mockSearchArticles;
  late MockSearchRepository mockRepository;

  final tArticle = Article(
    id: '1',
    title: 'Flutter News',
    summary: 'Flutter update summary',
    content: 'Content',
    imageUrl: 'https://example.com/img.png',
    category: ArticleCategory.technology,
    isBookmarked: false,
    commentCount: 10,
    publishedAt: DateTime(2024, 1, 15),
    sourceName: 'TechCrunch',
  );

  final tPaginatedArticles = PaginatedArticles(
    articles: [tArticle],
    nextCursor: null,
    hasMore: false,
  );

  setUp(() {
    mockSearchArticles = MockSearchArticles();
    mockRepository = MockSearchRepository();
    cubit = SearchCubit(
      searchArticles: mockSearchArticles,
      repository: mockRepository,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('SearchCubit', () {
    test('initial state is correct', () {
      expect(cubit.state, const SearchState());
    });

    blocTest<SearchCubit, SearchState>(
      'search emits [loading, loaded] on success after debounce',
      build: () {
        when(() => mockSearchArticles(
              query: 'flutter',
              cursor: null,
              limit: 20,
            )).thenAnswer((_) async => Success(tPaginatedArticles));
        return cubit;
      },
      act: (cubit) {
        cubit.search('flutter');
      },
      wait: const Duration(milliseconds: 400),
      expect: () => [
        const SearchState(
          status: SearchStatus.loading,
          query: 'flutter',
        ),
        SearchState(
          status: SearchStatus.loaded,
          query: 'flutter',
          articles: [tArticle],
          hasMore: false,
        ),
      ],
      verify: (_) {
        verify(() => mockSearchArticles(
              query: 'flutter',
              cursor: null,
              limit: 20,
            )).called(1);
      },
    );

    blocTest<SearchCubit, SearchState>(
      'search emits [loading, error] on failure',
      build: () {
        when(() => mockSearchArticles(
              query: 'error',
              cursor: null,
              limit: 20,
            )).thenAnswer((_) async => ErrorResult(
              const NetworkFailure(message: 'Network error'),
            ));
        return cubit;
      },
      act: (cubit) {
        cubit.search('error');
      },
      wait: const Duration(milliseconds: 400),
      expect: () => [
        const SearchState(
          status: SearchStatus.loading,
          query: 'error',
        ),
        const SearchState(
          status: SearchStatus.error,
          query: 'error',
          errorMessage: 'Network error',
        ),
      ],
    );

    blocTest<SearchCubit, SearchState>(
      'search with empty query resets to initial',
      build: () => cubit,
      seed: () => SearchState(
        status: SearchStatus.loaded,
        query: 'flutter',
        articles: [tArticle],
      ),
      act: (cubit) {
        cubit.search('');
      },
      expect: () => [
        const SearchState(
          status: SearchStatus.initial,
          articles: [],
          query: '',
          hasMore: false,
        ),
      ],
    );

    blocTest<SearchCubit, SearchState>(
      'rapid search calls are debounced and only last fires',
      build: () {
        when(() => mockSearchArticles(
              query: 'c',
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => Success(tPaginatedArticles));
        when(() => mockSearchArticles(
              query: 'co',
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => Success(tPaginatedArticles));
        when(() => mockSearchArticles(
              query: 'code',
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => Success(tPaginatedArticles));
        return cubit;
      },
      act: (cubit) {
        cubit.search('c');
        cubit.search('co');
        cubit.search('code');
      },
      wait: const Duration(milliseconds: 400),
      verify: (_) {
        verifyNever(() => mockSearchArticles(
              query: 'c',
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            ));
        verifyNever(() => mockSearchArticles(
              query: 'co',
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            ));
        verify(() => mockSearchArticles(
              query: 'code',
              cursor: null,
              limit: 20,
            )).called(1);
      },
    );

    blocTest<SearchCubit, SearchState>(
      'loadHistory emits state with search history',
      build: () {
        when(() => mockRepository.getSearchHistory())
            .thenAnswer((_) async => const Success(['flutter', 'dart']));
        return cubit;
      },
      act: (cubit) => cubit.loadHistory(),
      expect: () => [
        const SearchState(
          searchHistory: ['flutter', 'dart'],
        ),
      ],
    );

    blocTest<SearchCubit, SearchState>(
      'clearHistory emits state with empty history',
      build: () {
        when(() => mockRepository.clearSearchHistory())
            .thenAnswer((_) async => const Success(null));
        return cubit;
      },
      seed: () => const SearchState(
        searchHistory: ['flutter', 'dart'],
      ),
      act: (cubit) => cubit.clearHistory(),
      expect: () => [
        const SearchState(searchHistory: []),
      ],
    );

    blocTest<SearchCubit, SearchState>(
      'saveQuery saves and reloads history',
      build: () {
        when(() => mockRepository.saveSearchQuery('flutter'))
            .thenAnswer((_) async => const Success(null));
        when(() => mockRepository.getSearchHistory())
            .thenAnswer((_) async => const Success(['flutter']));
        return cubit;
      },
      act: (cubit) => cubit.saveQuery('flutter'),
      expect: () => [
        const SearchState(
          searchHistory: ['flutter'],
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.saveSearchQuery('flutter')).called(1);
        verify(() => mockRepository.getSearchHistory()).called(1);
      },
    );
  });
}
