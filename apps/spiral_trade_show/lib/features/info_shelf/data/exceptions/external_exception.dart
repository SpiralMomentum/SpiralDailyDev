import 'package:utils/utils.dart';

enum NetworkExternalExceptionType {
  timeout,
  noConnection,
  server,
  unknown,
}

class ExternalException extends Failure {
  const ExternalException({
    super.message,
    super.cause,
    super.stackTrace,
  });
}

class NetworkExternalException extends ExternalException {
  const NetworkExternalException(
    this.type, {
    super.message,
    super.cause,
    super.stackTrace,
  });

  final NetworkExternalExceptionType type;
}
