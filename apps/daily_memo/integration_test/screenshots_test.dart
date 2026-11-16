import 'package:app_analytics/app_analytics.dart';
import 'package:app_navigation/app_navigation.dart';
import 'package:apps.daily_memo/app/app.dart';
import 'package:apps.daily_memo/features/memo/data/datasources/memo_local_data_source.dart';
import 'package:apps.daily_memo/features/memo/data/repositories/memo_repository_impl.dart';
import 'package:apps.daily_memo/features/memo/domain/repositories/memo_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:utils/utils.dart';

// ---------------------------------------------------------------------------
// 마케팅 스크린샷 생성용 통합 테스트.
//
// 실행 (저장소 루트 기준):
//   cd apps/daily_memo
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshots_test.dart -d <simulator udid>
//
// 결과: tools/marketing/assets/shots/daily_memo/ko/<n>_<name>.png
// 더미 메모는 아래 seedMemos 로 인메모리 데이터 소스에 심는다 (실제 DB 미사용).
// ---------------------------------------------------------------------------

/// 화면에 보일 더미 메모. (제목, 내용, 수정일시). 목록은 memoId 순이므로 최신이 위.
const seedMemos = <(String, String, String)>[
  ('오늘 할 일', '우유, 달걀, 식빵 사기. 저녁 7시 요가', '2026-11-12 08:30:00.000'),
  ('회의 메모', '화요일 10시 디자인 리뷰, 자료는 금요일까지', '2026-11-11 14:05:00.000'),
  ('읽고 싶은 책', '어린 왕자 다시 읽기, 추천받은 소설 제목 적어 두기', '2026-11-10 21:40:00.000'),
  ('주말 계획', '토요일 북한산, 일요일 부모님 댁', '2026-11-08 19:12:00.000'),
  ('아이디어', '앱 아이콘을 노란 포스트잇 느낌으로 바꿔 보기', '2026-11-05 11:20:00.000'),
  ('운동 기록', '스쿼트 3세트, 러닝 3km', '2026-11-03 07:15:00.000'),
];

class InMemoryMemoLocalDataSource implements MemoLocalDataSource {
  final List<Map<String, Object?>> _store = [];
  int _nextId = 1;

  @override
  Future<Result<List<Map<String, Object?>>>> fetchAll() async {
    final sorted = List<Map<String, Object?>>.from(_store)
      ..sort((a, b) => (a['memoId'] as int).compareTo(b['memoId'] as int));
    return Success(sorted);
  }

  @override
  Future<Result<List<Map<String, Object?>>>> fetchById(int memoId) async =>
      Success(_store.where((m) => m['memoId'] == memoId).toList());

  @override
  Future<Result<void>> insert(Map<String, Object?> payload) async {
    _store.add({...payload, 'memoId': _nextId++});
    return const Success(null);
  }

  @override
  Future<Result<void>> update(int memoId, Map<String, Object?> payload) async {
    final index = _store.indexWhere((m) => m['memoId'] == memoId);
    if (index != -1) _store[index] = {...payload, 'memoId': memoId};
    return const Success(null);
  }

  @override
  Future<Result<void>> delete(int memoId) async {
    _store.removeWhere((m) => m['memoId'] == memoId);
    return const Success(null);
  }
}

Map<String, Object?> _row((String, String, String) memo) => {
      'title': memo.$1,
      'author': '',
      'content': memo.$2,
      'madeDateTime': memo.$3,
      'modifiedDateTime': memo.$3,
    };

Future<void> setupLocator() async {
  final getIt = GetIt.instance;
  await getIt.reset();
  final dataSource = InMemoryMemoLocalDataSource();
  for (final memo in seedMemos) {
    await dataSource.insert(_row(memo));
  }
  getIt
    ..registerLazySingleton<AnalyticsTracker>(() => DebugAnalyticsTracker())
    ..registerLazySingleton<MemoLocalDataSource>(() => dataSource)
    ..registerLazySingleton<RoutesController>(
      () => GoRouterRoutesController(
        navigationType: GoRouterNavigationType.path,
        popAllStrategy: GoRouterPopAllStrategy.pushReplacement,
      ),
    )
    ..registerLazySingleton<MemoRepository>(
      () => MemoRepositoryImpl(getIt.get()),
    );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// focus: 이 화면의 핵심 위젯들(합집합). 위치를 모아 테스트 끝에 reportData 로 보내면 드라이버가 사이드카 JSON 으로 남긴다.
  final focus = <String, Object>{};
  Future<void> shot(WidgetTester tester, String name, List<Finder> targets) async {
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    Rect? r;
    for (final f in targets) {
      for (var i = 0; i < f.evaluate().length; i++) {
        final x = tester.getRect(f.at(i));
        r = r == null ? x : r.expandToInclude(x);
      }
    }
    if (r != null) {
      focus[name] = {'rect': [r.left, r.top, r.right, r.bottom], 'dpr': tester.view.devicePixelRatio};
    }
    await binding.takeScreenshot(name);
  }

  testWidgets('마케팅 스크린샷 5장', (WidgetTester tester) async {
    WidgetsApp.debugAllowBannerOverride = false; // DEBUG 배너 숨김
    await setupLocator();
    await tester.pumpWidget(const App(locale: Locale('ko')));
    await tester.pumpAndSettle();

    // 0. 메모 목록
    expect(find.text(seedMemos.first.$1), findsOneWidget);
    await shot(tester, '0_list', [find.text(seedMemos.first.$1), find.textContaining('생성일').first]);

    // 1. 추가 화면 (입력 중)
    await tester.tap(find.text('추가'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.first, '장보기 목록');
    await tester.enterText(fields.last, '우유, 달걀, 식빵\n커피 원두 200g');
    await shot(tester, '1_add', [find.byType(TextField)]);

    // 저장. 이 환경에서는 저장 직후 목록 화면이 갱신되지 않는다(기존 memo_crud_test 도 같은 지점에서 실패).
    // 소재용으로는 저장소에 들어간 7건을 앱이 다시 읽어 온 화면(앱 재진입)을 찍는다.
    await tester.tap(find.text('추가').last);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const App(locale: Locale('ko')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(find.text('장보기 목록'), findsOneWidget);
    await shot(tester, '4_saved', [find.text('장보기 목록')]);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1200));
    await tester.pumpAndSettle();

    // 2. 수정 화면
    await tester.tap(find.text(seedMemos.first.$1));
    await tester.pumpAndSettle();
    await shot(tester, '2_edit', [find.byType(TextField)]);
    await tester.tap(find.text('수정').last); // 저장 -> 목록 복귀
    await tester.pumpAndSettle();

    // 3. 달력 탭
    await tester.tap(find.text('알림'));
    await shot(tester, '3_calendar', [find.byWidgetPredicate((w) => w.runtimeType.toString().startsWith('TableCalendar'))]);
    binding.reportData = {'focus': focus};
  });
}
