import 'package:app_analytics/app_analytics.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

class ServiceLocator {
  static Future<void> setup() async {
    // External
    getIt.registerLazySingleton<AnalyticsTracker>(
      () => DebugAnalyticsTracker(),
    );
  }
}
