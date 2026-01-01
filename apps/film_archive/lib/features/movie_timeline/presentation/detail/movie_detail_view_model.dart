import 'package:film_archive/features/movie_timeline/domain/usecases/get_movie_detail_use_case.dart';
import 'package:utils/utils.dart';

import 'movie_detail_view_data.dart';

class MovieDetailViewModel {
  MovieDetailViewModel({
    required this.getMovieDetailUseCase,
    required this.movieId,
  });

  final GetMovieDetailUseCase getMovieDetailUseCase;
  final int movieId;

  Future<Result<MovieDetailViewData>> load() async {
    final result = await getMovieDetailUseCase(movieId);
    return result.map(MovieDetailViewData.fromDomain);
  }
}
