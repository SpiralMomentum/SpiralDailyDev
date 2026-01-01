import 'package:film_archive/features/movie_timeline/data/models/movie_summary_dto.dart';
import 'package:film_archive/features/movie_timeline/domain/entities/movie_summary.dart';

class MovieSummaryMapper {
  const MovieSummaryMapper._();

  static MovieSummary toDomain(MovieSummaryDto dto) {
    return MovieSummary(
      id: dto.id,
      year: dto.year,
      title: dto.title,
      overview: dto.overview,
    );
  }
}
