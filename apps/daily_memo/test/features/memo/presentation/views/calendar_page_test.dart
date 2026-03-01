import 'package:apps.daily_memo/features/memo/domain/entities/memo_info_entity.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_bloc.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_event.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_state.dart';
import 'package:apps.daily_memo/features/memo/presentation/views/calendar_page.dart';
import 'package:apps.daily_memo/l10n/app_localizations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:table_calendar/table_calendar.dart';

class MockMemoBloc extends MockBloc<MemoEvent, MemoState> implements MemoBloc {}

void main() {
  late MockMemoBloc memoBloc;

  setUp(() {
    memoBloc = MockMemoBloc();
  });

  Widget buildSubject({MemoState? state}) {
    when(() => memoBloc.state).thenReturn(
      state ?? const MemoState(status: MemoStatus.getAllMemosSuccess),
    );

    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: BlocProvider<MemoBloc>.value(
        value: memoBloc,
        child: const Scaffold(
          body: CalendarPage(),
        ),
      ),
    );
  }

  group('CalendarPage', () {
    testWidgets('TableCalendar 위젯이 렌더링된다', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(TableCalendar<MemoInfoEntity>), findsOneWidget);
    });

    testWidgets('메모가 있는 날짜에 마커가 표시된다', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final memos = [
        MemoInfoEntity(
          uniqueId: 1,
          calendarDateTime: today,
          memoMadeDateTime: now,
          memoModifiedDateTime: now,
          title: 'Today Memo',
          content: 'Content',
        ),
      ];

      await tester.pumpWidget(buildSubject(
        state: MemoState(
          status: MemoStatus.getAllMemosSuccess,
          memos: memos,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(TableCalendar<MemoInfoEntity>), findsOneWidget);
    });

    testWidgets('메모가 없을 때도 캘린더가 정상적으로 렌더링된다', (tester) async {
      await tester.pumpWidget(buildSubject(
        state: const MemoState(
          status: MemoStatus.getAllMemosSuccess,
          memos: [],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(TableCalendar<MemoInfoEntity>), findsOneWidget);
    });

    testWidgets('캘린더 헤더의 좌우 화살표가 숨겨져 있다', (tester) async {
      await tester.pumpWidget(buildSubject());

      // HeaderStyle에서 leftChevronVisible, rightChevronVisible이 false로 설정됨
      // 따라서 chevron 아이콘이 표시되지 않아야 함
      expect(find.byIcon(Icons.chevron_left), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });
  });
}
