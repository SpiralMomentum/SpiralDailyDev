import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/settings/presentation/settings_page.dart';

import '../../support/pump.dart';

void main() {
  testWidgets('언어 선택 콜백, 기록 수 표시, 확인 후 전체 삭제', (tester) async {
    final languages = <String?>[];
    var counts = (attempts: 7, manifestations: 2);
    var cleared = 0;
    await tester.pumpLocalized(
      SettingsPage(
        language: null,
        onLanguageChanged: languages.add,
        loadHistory: () async => counts,
        clearHistory: () async {
          cleared++;
          counts = (attempts: 0, manifestations: 0);
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('시행 7회 · 발현 2회'), findsOneWidget);

    await tester.tap(find.byKey(const Key('language_ja')));
    await tester.pumpAndSettle();
    expect(languages, ['ja']);

    await tester.tap(find.byKey(const Key('delete_all')));
    await tester.pumpAndSettle();
    expect(find.text('기록을 모두 지울까요?'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(cleared, 0);

    await tester.tap(find.byKey(const Key('delete_all')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_delete')));
    await tester.pumpAndSettle();
    expect(cleared, 1);
    expect(find.text('시행 0회 · 발현 0회'), findsOneWidget);
    expect(find.text('기록을 모두 지웠어요'), findsOneWidget);
  });
}
