import 'package:film_archive/features/movie_timeline/domain/entities/movie_sort_option.dart';
import 'package:film_archive/features/movie_timeline/domain/entities/movie_summary.dart';
import 'package:film_archive/features/movie_timeline/domain/exceptions/movie_failure.dart';
import 'package:film_archive/features/movie_timeline/domain/repositories/movie_repository.dart';
import 'package:film_archive/features/movie_timeline/domain/usecases/get_movie_timeline_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/utils.dart';

class MockMovieRepository extends Mock implements MovieRepository {}

void main() {
  late MockMovieRepository mockRepository;
  late GetMovieTimelineUseCase useCase;

  setUp(() {
    mockRepository = MockMovieRepository();
    useCase = GetMovieTimelineUseCase(repository: mockRepository);
  });

  group('GetMovieTimelineUseCase', () {
    test('성공 시 Repository에서 반환한 MovieSummary 리스트를 그대로 반환한다', () async {
      final movies = [
        const MovieSummary(
          id: 1,
          year: 2023,
          title: 'Movie A',
          overview: 'Overview A',
        ),
        const MovieSummary(
          id: 2,
          year: 2022,
          title: 'Movie B',
          overview: 'Overview B',
        ),
      ];
      when(() => mockRepository.fetchTopMoviesByYearRange(
            startYear: 2022,
            endYear: 2023,
            sortOption: MovieSortOption.popularity,
          )).thenAnswer((_) async => Success(movies));

      final result = await useCase(
        startYear: 2022,
        endYear: 2023,
        sortOption: MovieSortOption.popularity,
      );

      expect(result.isSuccess, isTrue);
      final data = (result as Success<List<MovieSummary>>).data;
      expect(data, hasLength(2));
      expect(data[0].title, 'Movie A');
    });

    test('실패 시 Repository에서 반환한 ErrorResult를 그대로 반환한다', () async {
      when(() => mockRepository.fetchTopMoviesByYearRange(
            startYear: 2020,
            endYear: 2023,
            sortOption: MovieSortOption.revenue,
          )).thenAnswer((_) async => const ErrorResult(
            MovieFailure(message: '네트워크 에러'),
          ));

      final result = await useCase(
        startYear: 2020,
        endYear: 2023,
        sortOption: MovieSortOption.revenue,
      );

      expect(result.isError, isTrue);
      expect((result as ErrorResult).failure.message, '네트워크 에러');
    });

    test('정렬 옵션이 Repository에 정확히 전달된다', () async {
      when(() => mockRepository.fetchTopMoviesByYearRange(
            startYear: any(named: 'startYear'),
            endYear: any(named: 'endYear'),
            sortOption: MovieSortOption.voteCount,
          )).thenAnswer((_) async => const Success([]));

      await useCase(
        startYear: 2010,
        endYear: 2020,
        sortOption: MovieSortOption.voteCount,
      );

      verify(() => mockRepository.fetchTopMoviesByYearRange(
            startYear: 2010,
            endYear: 2020,
            sortOption: MovieSortOption.voteCount,
          )).called(1);
    });

    test('연도 범위 파라미터가 Repository에 정확히 전달된다', () async {
      when(() => mockRepository.fetchTopMoviesByYearRange(
            startYear: 2000,
            endYear: 2025,
            sortOption: MovieSortOption.popularity,
          )).thenAnswer((_) async => const Success([]));

      await useCase(
        startYear: 2000,
        endYear: 2025,
        sortOption: MovieSortOption.popularity,
      );

      verify(() => mockRepository.fetchTopMoviesByYearRange(
            startYear: 2000,
            endYear: 2025,
            sortOption: MovieSortOption.popularity,
          )).called(1);
    });
  });
}
