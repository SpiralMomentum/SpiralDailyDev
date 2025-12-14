class MovieApiException implements Exception {
  const MovieApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
