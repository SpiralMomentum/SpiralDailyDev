import 'dart:async';

import 'package:apps.news_reader/app/app.dart';
import 'package:apps.news_reader/app/di/service_locator.dart';
import 'package:apps.news_reader/app/route/app_routes.dart';
import 'package:apps.news_reader/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:utils/result/result.dart';

void main() {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
    };

    await ServiceLocator.setupLocatorSingleton();

    final settingsRepo = getIt.get<SettingsRepository>();
    final result = await settingsRepo.isOnboardingCompleted();

    final onboardingDone = switch (result) {
      Success(data: final completed) => completed,
      ErrorResult() => false,
    };

    final initialLocation = onboardingDone
        ? AppRoutes.feed.path
        : AppRoutes.onboarding.path;

    runApp(App(initialLocation: initialLocation));
  }, (error, stack) {
    debugPrint('Unhandled error: $error\n$stack');
  });
}
