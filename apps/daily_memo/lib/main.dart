import 'package:apps.daily_memo/app.dart';
import 'package:apps.daily_memo/app_bloc_observer.dart';
import 'package:apps.daily_memo/core/di/service_locator.dart';
import 'package:core_app_shell/core_app_shell.dart';

Future<void> main() async {
  await runSpiralRouterApp(
    bootstrap: () async {
      await ServiceLocator.setupLocatorSingleton();
    },
    router: createDailyMemoRouter(),
    blocObserver: const AppBlocObserver(),
  );
}
