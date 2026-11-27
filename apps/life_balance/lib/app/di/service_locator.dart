import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../features/kairos/presentation/kairos_card.dart';
import '../../features/ongoing_notification/data/midnight_scheduler.dart';
import '../../features/ongoing_notification/data/ongoing_notifier.dart';
import '../../features/profile/data/prefs_profile_repository.dart';
import '../../features/profile/domain/profile_repository.dart';
import '../../features/profile/presentation/onboarding/widget_pinner.dart';
import '../../features/widget_sync/data/home_widget_sync.dart';
import '../app_config.dart';
import '../background/background_dispatcher.dart';

final GetIt sl = GetIt.instance;

/// 백그라운드 작업 엔진 초기화. 플랫폼 호출을 감싸 테스트에서 대체한다.
abstract interface class BackgroundInitializer {
  Future<void> initialize();
}

class WorkmanagerBackgroundInitializer implements BackgroundInitializer {
  const WorkmanagerBackgroundInitializer();

  @override
  Future<void> initialize() => Workmanager().initialize(backgroundDispatcher);
}

/// 시각과 기기 로캘처럼 실행 환경에서 읽는 값.
class AppEnvironment {
  const AppEnvironment({required this.now, required this.deviceCountry});

  final DateTime Function() now;
  final String? Function() deviceCountry;
}

String? _platformCountry() => PlatformDispatcher.instance.locale.countryCode;

/// 저장소와 플랫폼 경계를 get_it에 interface 타입으로 등록한다.
/// 인자를 넘기면 기본 구현 대신 그 값을 쓴다(테스트용 fake).
abstract final class ServiceLocator {
  static Future<void> setup({
    required AppConfig config,
    required SharedPreferences prefs,
    AssetBundle? bundle,
    WidgetGateway? widgets,
    OngoingNotifier? notifier,
    RefreshScheduler? scheduler,
    BackgroundInitializer? background,
    WidgetPinner? pinner,
    UrlOpener? opener,
    DateTime Function()? now,
    String? Function()? deviceCountry,
  }) async {
    await sl.reset();
    sl
      ..registerSingleton<AppConfig>(config)
      ..registerSingleton<ProfileRepository>(PrefsProfileRepository(prefs))
      ..registerSingleton<AssetBundle>(bundle ?? rootBundle)
      ..registerSingleton<WidgetGateway>(widgets ?? const HomeWidgetGateway())
      ..registerSingleton<OngoingNotifier>(notifier ?? LocalOngoingNotifier())
      ..registerSingleton<RefreshScheduler>(
        scheduler ?? WorkmanagerRefreshScheduler(),
      )
      ..registerSingleton<BackgroundInitializer>(
        background ?? const WorkmanagerBackgroundInitializer(),
      )
      ..registerSingleton<WidgetPinner>(pinner ?? const HomeWidgetPinner())
      ..registerSingleton<UrlOpener>(opener ?? openExternal)
      ..registerSingleton<AppEnvironment>(
        AppEnvironment(
          now: now ?? DateTime.now,
          deviceCountry: deviceCountry ?? _platformCountry,
        ),
      );
  }
}
