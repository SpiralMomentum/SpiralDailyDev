import 'package:app_navigation/app_navigation.dart';
import 'package:apps.daily_memo/features/memo/domain/entities/memo_info_entity.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_bloc.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_event.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_state.dart';
import 'package:apps.daily_memo/features/memo/presentation/views/memo_list_page.dart';
import 'package:apps.daily_memo/l10n/app_localizations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMemoBloc extends MockBloc<MemoEvent, MemoState> implements MemoBloc {}

class MockRoutesController extends Mock implements RoutesController {}

void main() {
  late MockMemoBloc memoBloc;
  late MockRoutesController routesController;

  final memos = [
    MemoInfoEntity(
      uniqueId: 1,
      calendarDateTime: DateTime(2025, 1, 1),
      memoMadeDateTime: DateTime(2025, 1, 1, 10, 30),
      memoModifiedDateTime: DateTime(2025, 1, 1, 10, 30),
      title: '첫 번째 메모',
      content: '첫 번째 내용',
    ),
    MemoInfoEntity(
      uniqueId: 2,
      calendarDateTime: DateTime(2025, 1, 2),
      memoMadeDateTime: DateTime(2025, 1, 2, 11, 00),
      memoModifiedDateTime: DateTime(2025, 1, 2, 11, 00),
      title: '두 번째 메모',
      content: '두 번째 내용',
    ),
  ];

  setUp(() {
    memoBloc = MockMemoBloc();
    routesController = MockRoutesController();

    when(() => memoBloc.state).thenReturn(
      MemoState(status: MemoStatus.getAllMemosSuccess, memos: memos),
    );
  });

  Widget buildSubject({List<MemoInfoEntity> memoList = const []}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: BlocProvider<MemoBloc>.value(
        value: memoBloc,
        child: Scaffold(
          body: MemoListView(
            memos: memoList,
            routesController: routesController,
          ),
        ),
      ),
    );
  }

  group('MemoListView', () {
    testWidgets('메모 목록이 올바르게 렌더링된다', (tester) async {
      await tester.pumpWidget(buildSubject(memoList: memos));

      expect(find.text('첫 번째 메모'), findsOneWidget);
      expect(find.text('두 번째 메모'), findsOneWidget);
      expect(find.text('첫 번째 내용'), findsOneWidget);
      expect(find.text('두 번째 내용'), findsOneWidget);
    });

    testWidgets('빈 목록일 때 기본 메시지가 표시된다', (tester) async {
      await tester.pumpWidget(buildSubject(memoList: []));

      expect(find.text('데이터가 없습니다.'), findsOneWidget);
    });

    testWidgets('롱프레스 시 삭제 다이얼로그가 표시된다', (tester) async {
      await tester.pumpWidget(buildSubject(memoList: memos));

      // 첫 번째 메모 아이템을 롱프레스
      await tester.longPress(find.text('첫 번째 메모'));
      await tester.pumpAndSettle();

      // 삭제 다이얼로그 확인
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('삭제하기'), findsOneWidget);
    });

    testWidgets('빈 제목/내용인 메모는 플레이스홀더 텍스트로 표시된다', (tester) async {
      final emptyMemos = [
        MemoInfoEntity(
          uniqueId: 3,
          calendarDateTime: DateTime(2025, 1, 3),
          memoMadeDateTime: DateTime(2025, 1, 3, 12, 00),
          memoModifiedDateTime: DateTime(2025, 1, 3, 12, 00),
          title: '',
          content: '',
        ),
      ];

      when(() => memoBloc.state).thenReturn(
        MemoState(status: MemoStatus.getAllMemosSuccess, memos: emptyMemos),
      );

      await tester.pumpWidget(buildSubject(memoList: emptyMemos));

      expect(find.text('(빈 제목)'), findsOneWidget);
      expect(find.text('(빈 내용)'), findsOneWidget);
    });

    testWidgets('메모 아이템 사이에 구분선이 표시된다', (tester) async {
      await tester.pumpWidget(buildSubject(memoList: memos));

      expect(find.byType(Divider), findsOneWidget);
    });
  });
}
