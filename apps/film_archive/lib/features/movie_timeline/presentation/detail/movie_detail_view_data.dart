import 'package:film_archive/features/movie_timeline/domain/entities/movie_detail.dart';

class MovieDetailViewData {
  MovieDetailViewData({
    required this.title,
    required this.yearText,
    required this.countriesText,
    required this.genreText,
    required this.runtimeText,
    required this.ratingText,
    required this.overview,
  });

  factory MovieDetailViewData.fromDomain(MovieDetail detail) {
    return MovieDetailViewData(
      title: detail.title,
      yearText: detail.releaseYear != null ? '${detail.releaseYear}년' : '정보 없음',
      countriesText:
          detail.countries.isEmpty ? '정보 없음' : detail.countries.join(', '),
      genreText: detail.genres.isEmpty ? '정보 없음' : detail.genres.join(', '),
      runtimeText: detail.runtimeMinutes != null
          ? '${detail.runtimeMinutes}분'
          : '정보 없음',
      ratingText:
          detail.rating != null ? detail.rating!.toStringAsFixed(1) : '정보 없음',
      overview:
          detail.overview.isEmpty ? '소개 준비 중입니다.' : detail.overview,
    );
  }

  final String title;
  final String yearText;
  final String countriesText;
  final String genreText;
  final String runtimeText;
  final String ratingText;
  final String overview;
}
