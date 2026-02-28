import 'package:app_navigation/app_navigation.dart';
import 'package:apps.daily_memo/app/app.dart';
import 'package:app_analytics/app_analytics.dart';
import 'package:apps.daily_memo/features/memo/data/datasources/memo_local_data_source.dart';
import 'package:apps.daily_memo/features/memo/data/repositories/memo_repository_impl.dart';
import 'package:apps.daily_memo/features/memo/domain/repositories/memo_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:utils/utils.dart';

// ---------------------------------------------------------------------------
// 인메모리 MemoLocalDataSource 구현
// ---------------------------------------------------------------------------
/// sqflite 대신 메모리에 데이터를 저장하는 테스트용 데이터 소스.
/// autoincrement를 모방하기 위해 내부 카운터를 사용한다.
class InMemoryMemoLocalDataSource implements MemoLocalDataSource {
  final List<Map<String, Object?>> _store = [];
  int _nextId = 1;

  @override
  Future<Result<List<Map<String, Object?>>>> fetchAll() async {
    // 실제 DB와 동일하게 memoId 기준 오름차순 정렬
    final sorted = List<Map<String, Object?>>.from(_store)
      ..sort((a, b) => (a['memoId'] as int).compareTo(b['memoId'] as int));
    return Success(sorted);
  }

  @override
  Future<Result<List<Map<String, Object?>>>> fetchById(int memoId) async {
    final matches = _store.where((m) => m['memoId'] == memoId).toList();
    return Success(matches);
  }

  @override
  Future<Result<void>> insert(Map<String, Object?> payload) async {
    final row = Map<String, Object?>.from(payload);
    row['memoId'] = _nextId++;
    _store.add(row);
    return const Success(null);
  }

  @override
  Future<Result<void>> update(int memoId, Map<String, Object?> payload) async {
    final index = _store.indexWhere((m) => m['memoId'] == memoId);
    if (index != -1) {
      final updated = Map<String, Object?>.from(payload);
      updated['memoId'] = memoId;
      _store[index] = updated;
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> delete(int memoId) async {
    _store.removeWhere((m) => m['memoId'] == memoId);
    return const Success(null);
  }
}

// ---------------------------------------------------------------------------
// DI 헬퍼
// ---------------------------------------------------------------------------
final getIt = GetIt.instance;

Future<void> setupTestLocator() async {
  // 이전 등록이 남아 있을 수 있으므로 초기화한다
  await getIt.reset();

  getIt
    ..registerLazySingleton<AnalyticsTracker>(
      () => DebugAnalyticsTracker(),
    )
    ..registerLazySingleton<MemoLocalDataSource>(
      () => InMemoryMemoLocalDataSource(),
    )
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

// ---------------------------------------------------------------------------
// 메인 테스트
// ---------------------------------------------------------------------------
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('메모 CRUD 통합 테스트', () {
    setUp(() async {
      await setupTestLocator();
    });

    tearDown(() async {
      await getIt.reset();
    });

    testWidgets('메모 추가 -> 목록 확인 -> 수정 -> 삭제 전체 흐름',
        (WidgetTester tester) async {
      // ------------------------------------------------------------------
      // 앱 실행
      // ------------------------------------------------------------------
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      // 초기 상태: 데이터 없음 메시지 확인
      expect(find.text('데이터가 없습니다.'), findsOneWidget);

      // ------------------------------------------------------------------
      // 1. 메모 추가
      // ------------------------------------------------------------------
      // AppBar의 '추가' 버튼 탭
      await tester.tap(find.text('추가'));
      await tester.pumpAndSettle();

      // MemoView (추가 모드) 진입 확인 - AppBar 타이틀이 '추가'
      expect(find.text('제목'), findsOneWidget);
      expect(find.text('내용'), findsOneWidget);

      // 제목과 내용 입력
      final titleFields = find.byType(TextField);
      expect(titleFields, findsNWidgets(2));

      await tester.enterText(titleFields.first, '테스트 메모 제목');
      await tester.enterText(titleFields.last, '테스트 메모 내용입니다.');

      // BottomSheet의 '추가' 버튼 탭
      // BottomSheet 내부의 GestureDetector > Container > Text('추가')
      final addButtons = find.text('추가');
      // AppBar 타이틀에도 '추가'가 있으므로 BottomSheet 안의 것을 탭한다.
      // BottomSheet은 하단에 위치하므로 마지막 '추가' 텍스트를 탭한다.
      await tester.tap(addButtons.last);
      await tester.pumpAndSettle();

      // ------------------------------------------------------------------
      // 2. 목록에서 메모 확인
      // ------------------------------------------------------------------
      // 홈으로 돌아온 뒤 메모 제목이 목록에 표시되는지 확인
      expect(find.text('테스트 메모 제목'), findsOneWidget);
      expect(find.text('테스트 메모 내용입니다.'), findsOneWidget);

      // '데이터가 없습니다.' 메시지가 사라졌는지 확인
      expect(find.text('데이터가 없습니다.'), findsNothing);

      // ------------------------------------------------------------------
      // 3. 메모 수정
      // ------------------------------------------------------------------
      // 메모 아이템 탭하여 수정 화면으로 이동
      await tester.tap(find.text('테스트 메모 제목'));
      await tester.pumpAndSettle();

      // MemoView (수정 모드) 진입 확인 - AppBar 타이틀이 '수정'
      expect(find.text('수정').first, findsOneWidget);

      // 기존 내용이 채워져 있는지 확인
      final editTitleFields = find.byType(TextField);
      final titleController =
          (tester.widget<TextField>(editTitleFields.first)).controller!;
      final contentController =
          (tester.widget<TextField>(editTitleFields.last)).controller!;

      expect(titleController.text, '테스트 메모 제목');
      expect(contentController.text, '테스트 메모 내용입니다.');

      // 제목과 내용 수정
      await tester.enterText(editTitleFields.first, '수정된 메모 제목');
      await tester.enterText(editTitleFields.last, '수정된 메모 내용입니다.');

      // BottomSheet의 '수정' 버튼 탭
      final editButtons = find.text('수정');
      await tester.tap(editButtons.last);
      await tester.pumpAndSettle();

      // ------------------------------------------------------------------
      // 4. 수정된 내용 확인
      // ------------------------------------------------------------------
      // 홈 목록에서 수정된 내용이 반영되었는지 확인
      expect(find.text('수정된 메모 제목'), findsOneWidget);
      expect(find.text('수정된 메모 내용입니다.'), findsOneWidget);

      // 이전 내용이 사라졌는지 확인
      expect(find.text('테스트 메모 제목'), findsNothing);
      expect(find.text('테스트 메모 내용입니다.'), findsNothing);

      // ------------------------------------------------------------------
      // 5. 메모 삭제
      // ------------------------------------------------------------------
      // 메모 아이템 롱프레스하여 삭제 다이얼로그 표시
      await tester.longPress(find.text('수정된 메모 제목'));
      await tester.pumpAndSettle();

      // 삭제 다이얼로그에 메모 제목/내용이 표시되는지 확인
      expect(find.byType(AlertDialog), findsOneWidget);
      // 다이얼로그 내부에 메모 제목이 표시된다
      expect(find.text('수정된 메모 제목'), findsNWidgets(2)); // 목록 + 다이얼로그
      expect(find.text('수정된 메모 내용입니다.'), findsNWidgets(2)); // 목록 + 다이얼로그

      // '삭제하기' 버튼 탭
      await tester.tap(find.text('삭제하기'));
      await tester.pumpAndSettle();

      // ------------------------------------------------------------------
      // 6. 삭제 후 빈 목록 확인
      // ------------------------------------------------------------------
      // 메모가 삭제되어 빈 목록 메시지가 다시 표시되는지 확인
      expect(find.text('수정된 메모 제목'), findsNothing);
      expect(find.text('수정된 메모 내용입니다.'), findsNothing);
      expect(find.text('데이터가 없습니다.'), findsOneWidget);
    });
  });
}
