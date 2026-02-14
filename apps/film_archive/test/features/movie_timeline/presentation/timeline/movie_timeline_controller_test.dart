import 'package:film_archive/features/movie_timeline/domain/entities/movie_sort_option.dart';
import 'package:film_archive/features/movie_timeline/domain/entities/movie_summary.dart';
import 'package:film_archive/features/movie_timeline/domain/exceptions/movie_failure.dart';
import 'package:film_archive/features/movie_timeline/domain/usecases/get_movie_timeline_use_case.dart';
import 'package:film_archive/features/movie_timeline/presentation/timeline/movie_timeline_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/utils.dart';

class MockGetMovieTimelineUseCase extends Mock
    implements GetMovieTimelineUseCase {}

void main() {
  late MockGetMovieTimelineUseCase mockUseCase;
  late MovieTimelineController controller;

  setUp(() {
    mockUseCase = MockGetMovieTimelineUseCase();
    controller = MovieTimelineController(getMovieTimelineUseCase: mockUseCase);
  });

  tearDown(() {
    controller.dispose();
  });

  group('초기 상태', () {
    test('초기 상태는 빈 timeline, isLoading=false, popularity 정렬이다', () {
      expect(controller.state.timeline, isEmpty);
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.sortOption, MovieSortOption.popularity);
      expect(controller.state.errorMessage, isNull);
      expect(controller.state.inputMessage, isNull);
      expect(controller.state.noticeMessage, isNull);
    });
  });

  group('selectSortOption', () {
    test('다른 정렬 옵션 선택 시 상태가 변경되고 notifyListeners가 호출된다', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.selectSortOption(MovieSortOption.revenue);

      expect(controller.state.sortOption, MovieSortOption.revenue);
      expect(notified, isTrue);
    });

    test('같은 정렬 옵션 선택 시 상태가 변경되지 않는다', () {
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.selectSortOption(MovieSortOption.popularity);

      expect(notifyCount, 0);
      expect(controller.state.sortOption, MovieSortOption.popularity);
    });

    test('연속 정렬 옵션 변경이 정상 동작한다', () {
      controller.selectSortOption(MovieSortOption.voteCount);
      expect(controller.state.sortOption, MovieSortOption.voteCount);

      controller.selectSortOption(MovieSortOption.revenue);
      expect(controller.state.sortOption, MovieSortOption.revenue);
    });
  });

  group('buildTimeline - 입력 검증', () {
    test('숫자가 아닌 연도 입력 시 inputMessage를 설정한다', () async {
      await controller.buildTimeline(
        startYearText: 'abc',
        endYearText: '2023',
      );

      expect(controller.state.inputMessage, '연도는 숫자로 입력해주세요.');
      expect(controller.state.isLoading, isFalse);
    });

    test('시작 연도가 2000 미만이면 inputMessage를 설정한다', () async {
      await controller.buildTimeline(
        startYearText: '1999',
        endYearText: '2023',
      );

      expect(
        controller.state.inputMessage,
        '시작 연도는 2000년 이후로 입력해주세요.',
      );
    });

    test('시작 연도가 종료 연도보다 크면 inputMessage를 설정한다', () async {
      await controller.buildTimeline(
        startYearText: '2023',
        endYearText: '2020',
      );

      expect(controller.state.inputMessage, '연도 범위를 다시 확인해주세요.');
    });
  });

  group('buildTimeline - API 호출', () {
    test('성공 시 timeline에 데이터가 채워지고 isLoading이 false가 된다', () async {
      final movies = [
        const MovieSummary(
          id: 1,
          year: 2023,
          title: 'Movie 2023',
          overview: 'Overview',
        ),
      ];
      when(() => mockUseCase(
            startYear: 2023,
            endYear: 2023,
            sortOption: MovieSortOption.popularity,
          )).thenAnswer((_) async => Success(movies));

      await controller.buildTimeline(
        startYearText: '2023',
        endYearText: '2023',
      );

      expect(controller.state.timeline, hasLength(1));
      expect(controller.state.timeline[0].title, 'Movie 2023');
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.errorMessage, isNull);
    });

    test('로딩 중 상태 전이를 검증한다', () async {
      final states = <bool>[];
      controller.addListener(() {
        states.add(controller.state.isLoading);
      });

      when(() => mockUseCase(
            startYear: 2023,
            endYear: 2023,
            sortOption: MovieSortOption.popularity,
          )).thenAnswer((_) async => const Success([]));

      await controller.buildTimeline(
        startYearText: '2023',
        endYearText: '2023',
      );

      // 첫 notify: isLoading=true, 두 번째 notify: isLoading=false
      expect(states, [true, false]);
    });

    test('API 실패 시 errorMessage가 설정된다', () async {
      when(() => mockUseCase(
            startYear: 2023,
            endYear: 2023,
            sortOption: MovieSortOption.popularity,
          )).thenAnswer((_) async => const ErrorResult(
            MovieFailure(message: '서버 오류 발생'),
          ));

      await controller.buildTimeline(
        startYearText: '2023',
        endYearText: '2023',
      );

      expect(controller.state.errorMessage, '서버 오류 발생');
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.timeline, isEmpty);
    });

    test('결과가 빈 리스트이면 noticeMessage에 안내 문구가 설정된다', () async {
      when(() => mockUseCase(
            startYear: 2023,
            endYear: 2023,
            sortOption: MovieSortOption.popularity,
          )).thenAnswer((_) async => const Success([]));

      await controller.buildTimeline(
        startYearText: '2023',
        endYearText: '2023',
      );

      expect(controller.state.noticeMessage, '선택한 기간에 표시할 영화가 없습니다.');
    });

    test('일부 연도에 영화가 없으면 부분 누락 안내 문구가 설정된다', () async {
      // 2022~2023 범위인데 1개만 반환 -> expectedCount=2, movies.length=1
      final movies = [
        const MovieSummary(
          id: 1,
          year: 2023,
          title: 'Movie 2023',
          overview: 'Overview',
        ),
      ];
      when(() => mockUseCase(
            startYear: 2022,
            endYear: 2023,
            sortOption: MovieSortOption.popularity,
          )).thenAnswer((_) async => Success(movies));

      await controller.buildTimeline(
        startYearText: '2022',
        endYearText: '2023',
      );

      expect(
        controller.state.noticeMessage,
        '일부 연도에는 표시할 영화가 없어 제외되었습니다.',
      );
    });
  });
}
