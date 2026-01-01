import 'package:meta/meta.dart';

@immutable
class NetworkFailure {
  const NetworkFailure({
    required this.type,
    this.message,
    this.statusCode,
    this.rawBody,
  });

  final NetworkFailureType type;
  final String? message;
  final int? statusCode;
  final String? rawBody;

  @override
  String toString() {
    return 'NetworkFailure(type: $type, statusCode: $statusCode, message: $message)';
  }
}

enum NetworkFailureType {
  timeout,
  noConnection,
  server,
  client,
  unauthorized,
  forbidden,
  notFound,
  serialization,
  cancelled,
  unknown,
}
