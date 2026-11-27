import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/settings/presentation/names_page.dart';
import 'package:spend_ledger/features/settings/presentation/settings_cubit.dart';

import '../../support/fakes.dart';

void main() {
  testWidgets('one-character name is ignored with a message', (tester) async {
    late IngestHarness h;
    late SettingsCubit cubit;
    await tester.runAsync(() async {
      h = await openHarness();
      cubit = SettingsCubit(h.deps.settings, () async {});
      await cubit.load();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const NamesPage()),
      ),
    );

    await tester.enterText(find.byType(TextField).first, ' 홍 ');
    await tester.tap(find.byTooltip('추가').first);
    await tester.pump();

    expect(find.text('두 글자 이상 입력해 주세요.'), findsOneWidget);
    expect(cubit.state.settings.names.selfNames, isEmpty);

    await tester.runAsync(() async {
      await cubit.close();
      await h.close();
    });
  });
}
