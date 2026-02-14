import 'package:film_archive/features/movie_timeline/data/datasources/movie_remote_data_source.dart';
import 'package:film_archive/features/movie_timeline/data/models/movie_detail_dto.dart';
import 'package:film_archive/features/movie_timeline/data/models/movie_summary_dto.dart';
import 'package:film_archive/features/movie_timeline/data/repositories/movie_repository_impl.dart';
import 'package:film_archive/features/movie_timeline/domain/entities/movie_sort_option.dart';
import 'package:film_archive/features/movie_timeline/domain/exceptions/movie_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/utils.dart';

class MockMovieRemoteDataSource extends Mock
    implements MovieRemoteDataSource {}

void main() {
  late MockMovieRemoteDataSource mockDataSource;
  late MovieRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockMovieRemoteDataSource();
    repository = MovieRepositoryImpl(remoteDataSource: mockDataSource);
  });

  group('fetchTopMoviesByYearRange', () {
    test('DataSource가 성공하면 매핑된 MovieSummary 리스트를 반환한다', () async {
      when(() => mockDataSource.fetchTopMovieForYear(
            2023,
            MovieSortOption.popularity,
          )).thenAnswer((_) async => Success(MovieSummaryDto(
            id: 1,
            year: 2023,
            title: 'Movie 2023',
            overview: 'Overview 2023',
          )));
      when(() => mockDataSource.fetchTopMovieForYear(
            2022,
            MovieSortOption.popularity,
          )).thenAnswer((_) async => Success(MovieSummaryDto(
            id: 2,
            year: 2022,
            title: 'Movie 2022',
            overview: 'Overview 2022',
          )));

      final result = await repository.fetchTopMoviesByYearRange(
        startYear: 2022,
        endYear: 2023,
        sortOption: MovieSortOption.popularity,
      );

      expect(result.isSuccess, isTrue);
      final movies = (result as Success).data;
      expect(movies, hasLength(2));
      // endYear부터 역순으로 순회하므로 2023이 먼저
      expect(movies[0].year, 2023);
      expect(movies[1].year, 2022);
    });

    test('DataSource가 null을 반환하면 해당 연도를 건너뛴다', () async {
      when(() => mockDataSource.fetchTopMovieForYear(
            2023,
            MovieSortOption.popularity,
          )).thenAnswer((_) async => const Success(null));
      when(() => mockDataSource.fetchTopMovieForYear(
            2022,
            MovieSortOption.popularity,
          )).thenAnswer((_) async => Success(MovieSummaryDto(
            id: 2,
            year: 2022,
            title: 'Movie 2022',
            overview: 'Overview 2022',
          )));

      final result = await repository.fetchTopMoviesByYearRange(
        startYear: 2022,
        endYear: 2023,
        sortOption: MovieSortOption.popularity,
      );

      expect(result.isSuccess, isTrue);
      final movies = (result as Success).data;
      expect(movies, hasLength(1));
      expect(movies[0].year, 2022);
    });

    test('DataSource 에러 시 MovieFailure를 포함한 ErrorResult를 반환한다', () async {
      when(() => mockDataSource.fetchTopMovieForYear(
            2023,
            MovieSortOption.popularity,
          )).thenAnswer((_) async => const ErrorResult(
            NetworkFailure(message: '네트워크 오류'),
          ));

      final result = await repository.fetchTopMoviesByYearRange(
        startYear: 2023,
        endYear: 2023,
        sortOption: MovieSortOption.popularity,
      );

      expect(result.isError, isTrue);
      final failure = (result as ErrorResult).failure;
      expect(failure, isA<MovieFailure>());
      expect(failure.message, '네트워크 오류');
    });
  });

  group('fetchMovieDetail', () {
    test('DataSource 성공 시 매핑된 MovieDetail을 반환한다', () async {
      when(() => mockDataSource.fetchMovieDetail(550))
          .thenAnswer((_) async => Success(MovieDetailDto(
                id: 550,
                title: 'Fight Club',
                releaseYear: 1999,
                countries: ['United States of America'],
                genres: ['Drama'],
                runtimeMinutes: 139,
                rating: 8.4,
                overview: 'An insomniac office worker.',
              )));

      final result = await repository.fetchMovieDetail(550);

      expect(result.isSuccess, isTrue);
      final detail = (result as Success).data;
      expect(detail.id, 550);
      expect(detail.title, 'Fight Club');
      expect(detail.runtimeMinutes, 139);
    });

    test('DataSource 에러 시 MovieFailure를 반환한다', () async {
      when(() => mockDataSource.fetchMovieDetail(999))
          .thenAnswer((_) async => const ErrorResult(
                NetworkFailure(message: '요청한 영화를 찾을 수 없습니다.'),
              ));

      final result = await repository.fetchMovieDetail(999);

      expect(result.isError, isTrue);
      final failure = (result as ErrorResult).failure;
      expect(failure, isA<MovieFailure>());
      expect(failure.message, '요청한 영화를 찾을 수 없습니다.');
    });

    test('Failure에 message가 null이면 기본 메시지를 사용한다', () async {
      when(() => mockDataSource.fetchMovieDetail(1))
          .thenAnswer((_) async => const ErrorResult(
                NetworkFailure(message: null, code: 'network.unknown'),
              ));

      final result = await repository.fetchMovieDetail(1);

      expect(result.isError, isTrue);
      final failure = (result as ErrorResult).failure;
      expect(failure, isA<MovieFailure>());
      // _asMovieFailure에서 message가 null이면 기본 메시지 사용
      expect(failure.message, '영화 정보를 불러오지 못했습니다. 잠시 후 다시 시도해주세요.');
    });
  });
}
