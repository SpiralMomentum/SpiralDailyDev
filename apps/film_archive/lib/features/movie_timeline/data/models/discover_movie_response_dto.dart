class DiscoverMovieResponseDto {
  DiscoverMovieResponseDto({required this.results});

  factory DiscoverMovieResponseDto.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List<dynamic>? ?? const [];
    final parsed = rawResults
        .whereType<Map<String, dynamic>>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
    return DiscoverMovieResponseDto(results: parsed);
  }

  final List<Map<String, dynamic>> results;
}
