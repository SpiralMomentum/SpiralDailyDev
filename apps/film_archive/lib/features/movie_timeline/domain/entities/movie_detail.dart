class MovieDetail {
  const MovieDetail({
    required this.id,
    required this.title,
    required this.releaseYear,
    required this.countries,
    required this.genres,
    required this.runtimeMinutes,
    required this.rating,
    required this.overview,
  });

  final int id;
  final String title;
  final int? releaseYear;
  final List<String> countries;
  final List<String> genres;
  final int? runtimeMinutes;
  final double? rating;
  final String overview;
}
