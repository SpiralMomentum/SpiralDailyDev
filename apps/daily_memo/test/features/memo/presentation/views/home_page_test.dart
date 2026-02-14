import 'package:app_navigation/app_navigation.dart';
import 'package:apps.daily_memo/features/memo/domain/entities/memo_info_entity.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/home/home_bloc.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/home/home_event.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/home/home_state.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_bloc.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_event.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_state.dart';
import 'package:apps.daily_memo/features/memo/presentation/views/home_page.dart';
import 'package:apps.daily_memo/l10n/app_localizations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeBloc extends MockBloc<HomeEvent, HomeState> implements HomeBloc {}

class MockMemoBloc extends MockBloc<MemoEvent, MemoState> implements MemoBloc {}

class MockRoutesController extends Mock implements RoutesController {}

void main() {
  late MockHomeBloc homeBloc;
  late MockMemoBloc memoBloc;
  late MockRoutesController routesController;

  setUp(() {
    homeBloc = MockHomeBloc();
    memoBloc = MockMemoBloc();
    routesController = MockRoutesController();

    when(() => memoBloc.getRouteController).thenReturn(routesController);
  });

  Widget buildSubject({
    HomeState homeState = const HomeState(status: HomeStatus.success, index: 0),
    MemoState memoState = const MemoState(
      status: MemoStatus.getAllMemosSuccess,
    ),
  }) {
    when(() => homeBloc.state).thenReturn(homeState);
    when(() => memoBloc.state).thenReturn(memoState);

    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<HomeBloc>.value(value: homeBloc),
          BlocProvider<MemoBloc>.value(value: memoBloc),
        ],
        child: const HomeView(),
      ),
    );
  }

  group('HomeView', () {
    testWidgets('하단 네비게이션 바가 2개의 목적지를 렌더링한다', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(2));
      expect(find.text('홈'), findsOneWidget);
      expect(find.text('알림'), findsOneWidget);
    });

    testWidgets('index 0일 때 메모 목록 영역이 표시된다', (tester) async {
      await tester.pumpWidget(buildSubject(
        homeState: const HomeState(status: HomeStatus.success, index: 0),
        memoState: const MemoState(
          status: MemoStatus.getAllMemosSuccess,
          memos: [],
        ),
      ));

      // 빈 목록일 때의 기본 텍스트가 표시됨
      expect(find.text('데이터가 없습니다.'), findsOneWidget);
    });

    testWidgets('index 0에서 메모가 있으면 메모 제목이 표시된다', (tester) async {
      final memos = [
        MemoInfoEntity(
          uniqueId: 1,
          calendarDateTime: DateTime(2025, 1, 1),
          memoMadeDateTime: DateTime(2025, 1, 1, 10, 30),
          memoModifiedDateTime: DateTime(2025, 1, 1, 10, 30),
          title: 'Test Memo',
          content: 'Test Content',
        ),
      ];

      await tester.pumpWidget(buildSubject(
        homeState: const HomeState(status: HomeStatus.success, index: 0),
        memoState: MemoState(
          status: MemoStatus.getAllMemosSuccess,
          memos: memos,
        ),
      ));

      expect(find.text('Test Memo'), findsOneWidget);
    });

    testWidgets('AppBar에 추가 버튼이 렌더링된다', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('추가'), findsOneWidget);
    });
  });
}
