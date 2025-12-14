class MovieRepositoryException implements Exception {
  const MovieRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
