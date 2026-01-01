class MovieSummaryDto {
  MovieSummaryDto({
    required this.id,
    required this.year,
    required this.title,
    required this.overview,
  });

  factory MovieSummaryDto.fromJson(
    Map<String, dynamic> json, {
    required int fallbackYear,
  }) {
    final overview = (json['overview'] as String? ?? '').trim();
    final releaseDate = (json['release_date'] as String? ?? '').trim();
    final parsedYear = _parseReleaseYear(releaseDate) ?? fallbackYear;
    return MovieSummaryDto(
      id: json['id'] as int,
      year: parsedYear,
      title: (json['title'] as String? ??
              json['name'] as String? ??
              '제목 미정')
          .trim(),
      overview: overview,
    );
  }

  final int id;
  final int year;
  final String title;
  final String overview;
}

int? _parseReleaseYear(String date) {
  if (date.isEmpty || date.length < 4) {
    return null;
  }
  return int.tryParse(date.substring(0, 4));
}
