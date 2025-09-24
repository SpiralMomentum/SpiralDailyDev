library core_di;

import 'dart:async';

import 'package:get_it/get_it.dart';

/// Global [GetIt] instance used across the mono-repo.
final GetIt serviceLocator = GetIt.instance;

/// Function signature used by features to register their dependencies.
typedef DependencyRegistrar = FutureOr<void> Function(GetIt getIt);

/// Registers all dependencies provided by [registrars].
///
/// Each registrar receives the shared [GetIt] instance, making it possible to
/// wire cross package dependencies from a single place.
Future<void> registerDependencies(
  Iterable<DependencyRegistrar> registrars,
) async {
  for (final DependencyRegistrar registrar in registrars) {
    await registrar(serviceLocator);
  }
}

/// Convenience method for retrieving a registered dependency.
T getDependency<T extends Object>() => serviceLocator.get<T>();

/// Clears every registered dependency. Useful for tests.
Future<void> resetDependencies() => serviceLocator.reset();
