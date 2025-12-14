class MovieSummary {
  const MovieSummary({
    required this.id,
    required this.year,
    required this.title,
    required this.overview,
  });

  final int id;
  final int year;
  final String title;
  final String overview;

  String get displayOverview =>
      overview.isEmpty ? '소개 준비 중입니다.' : overview;
}
