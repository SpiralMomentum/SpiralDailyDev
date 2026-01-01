import 'package:film_archive/features/movie_timeline/domain/entities/movie_detail.dart';
import 'package:film_archive/features/movie_timeline/domain/repositories/movie_repository.dart';
import 'package:utils/utils.dart';

class GetMovieDetailUseCase {
  const GetMovieDetailUseCase({required MovieRepository repository})
      : _repository = repository;

  final MovieRepository _repository;

  Future<Result<MovieDetail>> call(int movieId) {
    return _repository.fetchMovieDetail(movieId);
  }
}
