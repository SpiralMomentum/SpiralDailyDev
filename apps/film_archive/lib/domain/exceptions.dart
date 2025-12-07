class MovieRepositoryException implements Exception {
  const MovieRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MovieApiException implements Exception {
  const MovieApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
