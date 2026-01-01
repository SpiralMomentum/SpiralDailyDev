abstract class Failure {
  const Failure({
    this.message,
    this.code,
    this.cause,
    this.stackTrace,
  });

  final String? message;
  final String? code;
  final Object? cause;
  final StackTrace? stackTrace;
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message,
    super.code,
    super.cause,
    super.stackTrace,
  });
}

class ParsingFailure extends Failure {
  const ParsingFailure({
    super.message,
    super.code,
    super.cause,
    super.stackTrace,
  });
}

class LocalStorageFailure extends Failure {
  const LocalStorageFailure({
    super.message,
    super.code,
    super.cause,
    super.stackTrace,
  });
}

class BusinessRuleFailure extends Failure {
  const BusinessRuleFailure({
    super.message,
    super.code,
    super.cause,
    super.stackTrace,
  });
}
