import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/l10n/app_localizations.dart';

Widget localized(Widget child, {String locale = 'ko'}) => MaterialApp(
      locale: Locale(locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    );

extension PumpLocalized on WidgetTester {
  Future<void> pumpLocalized(Widget child, {String locale = 'ko'}) async {
    view.physicalSize = const Size(1080, 2280);
    view.devicePixelRatio = 3;
    addTearDown(view.reset);
    await pumpWidget(localized(child, locale: locale));
  }
}

extension PumpUntil on WidgetTester {
  /// 무한 애니메이션(스피너)이 있어 pumpAndSettle 을 쓸 수 없는 구간에서 [finder] 가 나타날 때까지 기다린다.
  Future<void> pumpUntil(Finder finder, {Duration timeout = const Duration(seconds: 20)}) async {
    final end = binding.clock.now().add(timeout);
    while (finder.evaluate().isEmpty) {
      if (binding.clock.now().isAfter(end)) throw TestFailure('pumpUntil timeout: $finder');
      await pump(const Duration(milliseconds: 100));
    }
    await pump();
  }
}
