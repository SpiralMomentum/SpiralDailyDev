import 'package:apps.daily_memo/features/memo/domain/entities/memo_info_entity.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_bloc.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_event.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_state.dart';
import 'package:apps.daily_memo/features/memo/presentation/views/memo_view.dart';
import 'package:apps.daily_memo/l10n/app_localizations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMemoBloc extends MockBloc<MemoEvent, MemoState> implements MemoBloc {}

void main() {
  late MockMemoBloc memoBloc;

  setUpAll(() {
    registerFallbackValue(GetAllMemos());
  });

  setUp(() {
    memoBloc = MockMemoBloc();
    when(() => memoBloc.state).thenReturn(
      const MemoState(status: MemoStatus.initial),
    );
  });

  Widget buildSubject({MemoInfoEntity? memoInfo}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: BlocProvider<MemoBloc>.value(
        value: memoBloc,
        child: MemoView(memoInfo: memoInfo),
      ),
    );
  }

  group('MemoView - 추가 모드', () {
    testWidgets('제목과 내용 입력 필드가 렌더링된다', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('제목'), findsOneWidget);
      expect(find.text('내용'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('AppBar에 추가 타이틀이 표시된다', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // AppBar 타이틀 "추가" + BottomSheet 버튼 "추가" = 2개
      expect(find.text('추가'), findsNWidgets(2));
    });

    testWidgets('하단 추가 버튼 탭 시 AddMemo 이벤트가 발행된다', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // 제목 입력
      await tester.enterText(find.byType(TextField).first, '새 메모 제목');
      // 내용 입력
      await tester.enterText(find.byType(TextField).last, '새 메모 내용');

      // "추가" 텍스트가 2곳에 있으므로 last로 하단 버튼을 선택
      await tester.tap(find.text('추가').last);
      await tester.pump();

      verify(() => memoBloc.add(any(that: isA<AddMemo>()))).called(1);
    });
  });

  group('MemoView - 수정 모드', () {
    final existingMemo = MemoInfoEntity(
      uniqueId: 1,
      calendarDateTime: DateTime(2025, 1, 1),
      memoMadeDateTime: DateTime(2025, 1, 1, 10, 30),
      memoModifiedDateTime: DateTime(2025, 1, 1, 10, 30),
      title: '기존 제목',
      content: '기존 내용',
    );

    testWidgets('AppBar에 수정 타이틀이 표시된다', (tester) async {
      await tester.pumpWidget(buildSubject(memoInfo: existingMemo));
      await tester.pumpAndSettle();

      // AppBar 타이틀 "수정" + BottomSheet 버튼 "수정" = 2개
      expect(find.text('수정'), findsNWidgets(2));
    });

    testWidgets('기존 메모의 제목과 내용이 미리 채워진다', (tester) async {
      await tester.pumpWidget(buildSubject(memoInfo: existingMemo));
      await tester.pumpAndSettle();

      final titleField = tester.widget<TextField>(find.byType(TextField).first);
      final contentField =
          tester.widget<TextField>(find.byType(TextField).last);

      expect(titleField.controller!.text, '기존 제목');
      expect(contentField.controller!.text, '기존 내용');
    });

    testWidgets('하단 수정 버튼 탭 시 UpdateMemo 이벤트가 발행된다', (tester) async {
      await tester.pumpWidget(buildSubject(memoInfo: existingMemo));
      await tester.pumpAndSettle();

      // "수정" 텍스트가 2곳에 있으므로 last로 하단 버튼을 선택
      await tester.tap(find.text('수정').last);
      await tester.pump();

      verify(() => memoBloc.add(any(that: isA<UpdateMemo>()))).called(1);
    });
  });
}
