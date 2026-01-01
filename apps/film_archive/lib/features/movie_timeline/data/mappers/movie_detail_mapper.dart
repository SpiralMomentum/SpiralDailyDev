import 'package:film_archive/features/movie_timeline/data/models/movie_detail_dto.dart';
import 'package:film_archive/features/movie_timeline/domain/entities/movie_detail.dart';

class MovieDetailMapper {
  const MovieDetailMapper._();

  static MovieDetail toDomain(MovieDetailDto dto) {
    return MovieDetail(
      id: dto.id,
      title: dto.title,
      releaseYear: dto.releaseYear,
      countries: dto.countries,
      genres: dto.genres,
      runtimeMinutes: dto.runtimeMinutes,
      rating: dto.rating,
      overview: dto.overview,
    );
  }
}
