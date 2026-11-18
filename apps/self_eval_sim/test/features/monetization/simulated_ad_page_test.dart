import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/monetization/presentation/simulated_ad_page.dart';

import '../../support/pump.dart';

void main() {
  Future<bool?> Function() opener(WidgetTester tester, List<bool?> results) => () async {
        final ctx = tester.element(find.byKey(const Key('open')));
        final r = await Navigator.of(ctx).push(SimulatedAdPage.route(const Duration(seconds: 3)));
        results.add(r);
        return r;
      };

  Widget host() => Builder(
        builder: (_) => const Scaffold(body: Text('host', key: Key('open'))),
      );

  testWidgets('카운트다운이 끝나면 true(보상)로 닫힌다', (tester) async {
    final results = <bool?>[];
    await tester.pumpLocalized(host());
    opener(tester, results)();
    await tester.pumpAndSettle();
    expect(find.text('광고 재생 중 · 3초'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('광고 재생 중 · 2초'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(results, [true]);
  });

  testWidgets('닫기 버튼은 false(보상 없음)', (tester) async {
    final results = <bool?>[];
    await tester.pumpLocalized(host());
    opener(tester, results)();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ad_close')));
    await tester.pumpAndSettle();
    expect(results, [false]);
  });
}
