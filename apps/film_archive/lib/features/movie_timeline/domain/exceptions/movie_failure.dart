import 'package:utils/utils.dart';

class MovieFailure extends Failure {
  const MovieFailure({
    super.message,
    super.code,
    super.cause,
    super.stackTrace,
  });
}
