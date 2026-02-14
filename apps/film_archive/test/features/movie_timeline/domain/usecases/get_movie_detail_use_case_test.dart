import 'package:film_archive/features/movie_timeline/domain/entities/movie_detail.dart';
import 'package:film_archive/features/movie_timeline/domain/exceptions/movie_failure.dart';
import 'package:film_archive/features/movie_timeline/domain/repositories/movie_repository.dart';
import 'package:film_archive/features/movie_timeline/domain/usecases/get_movie_detail_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/utils.dart';

class MockMovieRepository extends Mock implements MovieRepository {}

void main() {
  late MockMovieRepository mockRepository;
  late GetMovieDetailUseCase useCase;

  setUp(() {
    mockRepository = MockMovieRepository();
    useCase = GetMovieDetailUseCase(repository: mockRepository);
  });

  group('GetMovieDetailUseCase', () {
    test('성공 시 Repository에서 반환한 MovieDetail을 그대로 반환한다', () async {
      const detail = MovieDetail(
        id: 550,
        title: 'Fight Club',
        releaseYear: 1999,
        countries: ['United States of America'],
        genres: ['Drama'],
        runtimeMinutes: 139,
        rating: 8.4,
        overview: 'An insomniac office worker.',
      );
      when(() => mockRepository.fetchMovieDetail(550))
          .thenAnswer((_) async => const Success(detail));

      final result = await useCase(550);

      expect(result.isSuccess, isTrue);
      final data = (result as Success).data;
      expect(data.id, 550);
      expect(data.title, 'Fight Club');
    });

    test('실패 시 Repository에서 반환한 ErrorResult를 그대로 반환한다', () async {
      when(() => mockRepository.fetchMovieDetail(999))
          .thenAnswer((_) async => const ErrorResult(
                MovieFailure(message: '영화를 찾을 수 없습니다.'),
              ));

      final result = await useCase(999);

      expect(result.isError, isTrue);
      expect((result as ErrorResult).failure.message, '영화를 찾을 수 없습니다.');
    });

    test('영화 ID가 Repository에 정확히 전달된다', () async {
      const detail = MovieDetail(
        id: 278,
        title: 'The Shawshank Redemption',
        releaseYear: 1994,
        countries: ['United States of America'],
        genres: ['Drama', 'Crime'],
        runtimeMinutes: 142,
        rating: 8.7,
        overview: 'Imprisoned in the 1940s.',
      );
      when(() => mockRepository.fetchMovieDetail(278))
          .thenAnswer((_) async => const Success(detail));

      await useCase(278);

      verify(() => mockRepository.fetchMovieDetail(278)).called(1);
    });
  });
}
