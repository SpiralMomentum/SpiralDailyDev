import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/result/result.dart';
import 'package:utils/result/failure.dart';
import 'package:apps.news_reader/features/news_feed/domain/entities/article.dart';
import 'package:apps.news_reader/features/article_detail/domain/usecases/get_article_detail.dart';
import 'package:apps.news_reader/features/bookmarks/domain/usecases/toggle_bookmark.dart';
import 'package:apps.news_reader/features/article_detail/presentation/bloc/article_detail_bloc.dart';
import 'package:apps.news_reader/features/article_detail/presentation/bloc/article_detail_event.dart';
import 'package:apps.news_reader/features/article_detail/presentation/bloc/article_detail_state.dart';

class MockGetArticleDetail extends Mock implements GetArticleDetail {}

class MockToggleBookmark extends Mock implements ToggleBookmark {}

void main() {
  late MockGetArticleDetail getArticleDetail;
  late MockToggleBookmark toggleBookmark;

  final tArticle = Article(
    id: 'art-1',
    title: 'Detail Title',
    summary: 'Summary',
    content: 'Full content here',
    imageUrl: 'url',
    category: ArticleCategory.science,
    isBookmarked: false,
    commentCount: 3,
    publishedAt: DateTime(2024, 1, 1),
    sourceName: 'Source',
  );

  setUp(() {
    getArticleDetail = MockGetArticleDetail();
    toggleBookmark = MockToggleBookmark();
  });

  setUpAll(() {
    registerFallbackValue(tArticle);
  });

  ArticleDetailBloc buildBloc() => ArticleDetailBloc(
        getArticleDetail: getArticleDetail,
        toggleBookmark: toggleBookmark,
      );

  group('ArticleDetailBloc', () {
    blocTest<ArticleDetailBloc, ArticleDetailState>(
      'emits [loading, loaded] when Started succeeds',
      build: () {
        when(() => getArticleDetail('art-1'))
            .thenAnswer((_) async => Success(tArticle));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ArticleDetailStarted('art-1')),
      expect: () => [
        const ArticleDetailState(status: ArticleDetailStatus.loading),
        ArticleDetailState(
          status: ArticleDetailStatus.loaded,
          article: tArticle,
        ),
      ],
    );

    blocTest<ArticleDetailBloc, ArticleDetailState>(
      'emits [loading, error] when Started fails',
      build: () {
        when(() => getArticleDetail('art-1')).thenAnswer(
          (_) async =>
              ErrorResult(const NetworkFailure(message: 'Not found')),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ArticleDetailStarted('art-1')),
      expect: () => [
        const ArticleDetailState(status: ArticleDetailStatus.loading),
        const ArticleDetailState(
          status: ArticleDetailStatus.error,
          errorMessage: 'Not found',
        ),
      ],
    );

    blocTest<ArticleDetailBloc, ArticleDetailState>(
      'toggles bookmark on article',
      build: () {
        when(() => toggleBookmark(any()))
            .thenAnswer((_) async => const Success(true));
        return buildBloc();
      },
      seed: () => ArticleDetailState(
        status: ArticleDetailStatus.loaded,
        article: tArticle,
      ),
      act: (bloc) => bloc.add(const ArticleDetailBookmarkToggled()),
      expect: () => [
        ArticleDetailState(
          status: ArticleDetailStatus.loaded,
          article: tArticle.copyWith(isBookmarked: true),
        ),
      ],
    );

    blocTest<ArticleDetailBloc, ArticleDetailState>(
      'does not emit when BookmarkToggled fails',
      build: () {
        when(() => toggleBookmark(any())).thenAnswer(
          (_) async =>
              ErrorResult(const NetworkFailure(message: 'Network error')),
        );
        return buildBloc();
      },
      seed: () => ArticleDetailState(
        status: ArticleDetailStatus.loaded,
        article: tArticle,
      ),
      act: (bloc) => bloc.add(const ArticleDetailBookmarkToggled()),
      expect: () => <ArticleDetailState>[],
    );

    blocTest<ArticleDetailBloc, ArticleDetailState>(
      'does nothing on BookmarkToggled when article is null',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const ArticleDetailBookmarkToggled()),
      expect: () => <ArticleDetailState>[],
    );

    blocTest<ArticleDetailBloc, ArticleDetailState>(
      'refreshes article detail on ArticleDetailRefreshed',
      build: () {
        when(() => getArticleDetail('art-1'))
            .thenAnswer((_) async => Success(tArticle.copyWith(commentCount: 5)));
        return buildBloc();
      },
      seed: () => ArticleDetailState(
        status: ArticleDetailStatus.loaded,
        article: tArticle,
      ),
      act: (bloc) {
        // _articleId is set via ArticleDetailStarted, so we need to fire Started first
        // But since seed already has state, we need _articleId to be set.
        // ArticleDetailRefreshed relies on _articleId being set previously.
        // Since _articleId is null without a prior Started event, this should do nothing.
        bloc.add(const ArticleDetailRefreshed());
      },
      expect: () => <ArticleDetailState>[],
    );

    blocTest<ArticleDetailBloc, ArticleDetailState>(
      'does not throw when share requested with no article',
      build: () => ArticleDetailBloc(
        getArticleDetail: getArticleDetail,
        toggleBookmark: toggleBookmark,
      ),
      act: (bloc) => bloc.add(const ArticleDetailShareRequested()),
      expect: () => <ArticleDetailState>[],
    );

    blocTest<ArticleDetailBloc, ArticleDetailState>(
      'refreshes after Started sets _articleId',
      build: () {
        when(() => getArticleDetail('art-1'))
            .thenAnswer((_) async => Success(tArticle));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const ArticleDetailStarted('art-1'));
        await Future<void>.delayed(Duration.zero);
        // Now update mock to return updated article
        when(() => getArticleDetail('art-1'))
            .thenAnswer((_) async => Success(tArticle.copyWith(commentCount: 10)));
        bloc.add(const ArticleDetailRefreshed());
      },
      expect: () => [
        const ArticleDetailState(status: ArticleDetailStatus.loading),
        ArticleDetailState(
          status: ArticleDetailStatus.loaded,
          article: tArticle,
        ),
        ArticleDetailState(
          status: ArticleDetailStatus.loaded,
          article: tArticle.copyWith(commentCount: 10),
        ),
      ],
    );
  });
}
