import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/settings/presentation/settings_cubit.dart';
import 'package:spend_ledger/features/settings/presentation/theme_page.dart';
import 'package:spend_ledger/features/theme/domain/palette.dart';

import '../../support/fakes.dart';

void main() {
  late IngestHarness h;
  late SettingsCubit cubit;

  Future<void> show(WidgetTester tester) async {
    await tester.runAsync(() async {
      h = await openHarness();
      cubit = SettingsCubit(h.deps.settings, () async {});
      await cubit.load();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const ThemePage()),
      ),
    );
    await tester.pump();
  }

  testWidgets('밝기 세그먼트 선택이 저장된다', (tester) async {
    await show(tester);
    await tester.tap(find.text('어둡게'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    expect(cubit.state.settings.themeMode, AppThemeMode.dark);
    await tester.runAsync(h.close);
  });

  testWidgets('선택된 테마 카드에 체크 표시', (tester) async {
    await show(tester);
    expect(
      find.descendant(
        of: find.widgetWithText(Card, '베이지'),
        matching: find.byIcon(Icons.check),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(Card, '남색'),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
    await tester.runAsync(h.close);
  });

  testWidgets('테마 카드를 누르면 테마가 바뀐다', (tester) async {
    await show(tester);
    await tester.tap(find.text('베이지'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    expect(cubit.state.settings.themeId, AppThemeId.beige);
    await tester.runAsync(h.close);
  });
}
