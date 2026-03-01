import 'package:meta/meta.dart';
import 'package:utils/result/failure.dart' as utils;

@immutable
class NetworkFailure extends utils.Failure {
  const NetworkFailure({
    required this.type,
    super.message,
    this.statusCode,
    this.rawBody,
    super.cause,
    super.stackTrace,
  });

  final NetworkFailureType type;
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
