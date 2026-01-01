import 'package:meta/meta.dart';

import 'network_failure.dart';

@immutable
class NetworkException implements Exception {
  const NetworkException(this.failure, {this.cause});

  final NetworkFailure failure;
  final Object? cause;

  String get message => failure.message ?? failure.type.name;

  @override
  String toString() => 'NetworkException(${failure.type}, $message)';
}
