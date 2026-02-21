import 'dart:async';

import 'package:app_logging/app_logging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Firebase Crashlytics 기반 [CrashReporter] 구현체.
class FirebaseCrashReporter extends CrashReporter {
  FirebaseCrashReporter({FirebaseCrashlytics? crashlytics})
      : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  @override
  FutureOr<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) {
    return _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason ?? 'non-fatal error',
      fatal: fatal,
    );
  }

  @override
  FutureOr<void> setUserId(String id) {
    return _crashlytics.setUserIdentifier(id);
  }

  @override
  FutureOr<void> setCustomKey(String key, Object value) {
    return _crashlytics.setCustomKey(key, value);
  }

  @override
  FutureOr<void> log(String message) {
    return _crashlytics.log(message);
  }
}
