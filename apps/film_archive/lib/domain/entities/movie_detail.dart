class MovieDetail {
  MovieDetail({
    required this.id,
    required this.title,
    required this.releaseYear,
    required this.countries,
    required this.genres,
    required this.runtimeMinutes,
    required this.rating,
    required this.overview,
  });

  factory MovieDetail.fromJson(Map<String, dynamic> json) {
    final releaseDate = (json['release_date'] as String? ?? '').trim();
    final countries = (json['production_countries'] as List<dynamic>? ?? [])
        .map((entry) => (entry as Map<String, dynamic>)['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
    final genres = (json['genres'] as List<dynamic>? ?? [])
        .map((entry) => (entry as Map<String, dynamic>)['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    return MovieDetail(
      id: json['id'] as int,
      title: (json['title'] as String? ??
              json['name'] as String? ??
              '제목 미정')
          .trim(),
      releaseYear: _parseReleaseYear(releaseDate),
      countries: countries,
      genres: genres,
      runtimeMinutes: json['runtime'] as int?,
      rating: (json['vote_average'] as num?)?.toDouble(),
      overview: (json['overview'] as String? ?? '').trim(),
    );
  }

  final int id;
  final String title;
  final int? releaseYear;
  final List<String> countries;
  final List<String> genres;
  final int? runtimeMinutes;
  final double? rating;
  final String overview;

  String get displayOverview =>
      overview.isEmpty ? '소개 준비 중입니다.' : overview;

  String get yearText =>
      releaseYear != null ? '$releaseYear년' : '정보 없음';

  String get countriesText =>
      countries.isEmpty ? '정보 없음' : countries.join(', ');

  String get genreText => genres.isEmpty ? '정보 없음' : genres.join(', ');

  String get runtimeText =>
      runtimeMinutes != null ? '$runtimeMinutes분' : '정보 없음';

  String get ratingText =>
      rating != null ? rating!.toStringAsFixed(1) : '정보 없음';
}

int? _parseReleaseYear(String date) {
  if (date.isEmpty || date.length < 4) {
    return null;
  }
  return int.tryParse(date.substring(0, 4));
}
