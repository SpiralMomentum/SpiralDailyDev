import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import '../features/settings/domain/settings.dart';
import 'app_config.dart';
import 'di/service_locator.dart';
import 'self_eval_app.dart';

/// 의존성을 조립하고 저장된 언어 설정을 읽어 루트 위젯을 만든다.
Future<Widget> bootstrap(AppConfig config) async {
  final navigatorKey = GlobalKey<NavigatorState>();
  await FlutterGemma.initialize();
  await ServiceLocator.setup(config, navigatorKey);
  final saved = await sl<LanguagePreferenceRepository>().load();
  return SelfEvalApp(
    navigatorKey: navigatorKey,
    language: ValueNotifier<String?>(saved.dataOrNull),
  );
}
