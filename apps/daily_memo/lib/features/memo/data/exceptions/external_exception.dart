import 'package:utils/utils.dart';

class ExternalException extends Failure {
  const ExternalException({
    super.message,
    super.cause,
    super.stackTrace,
  });
}

class LocalStorageExternalException extends ExternalException {
  const LocalStorageExternalException({
    super.message,
    super.cause,
    super.stackTrace,
  });
}
