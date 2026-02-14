import 'package:apps.daily_memo/features/memo/domain/entities/memo_info_entity.dart';
import 'package:apps.daily_memo/features/memo/domain/repositories/memo_repository.dart';
import 'package:apps.daily_memo/features/memo/domain/usecases/get_all_memos_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/utils.dart';

class MockMemoRepository extends Mock implements MemoRepository {}

void main() {
  late MockMemoRepository repository;
  late GetAllMemosUseCase useCase;

  setUp(() {
    repository = MockMemoRepository();
    useCase = GetAllMemosUseCase(repository: repository);
  });

  final memos = [
    MemoInfoEntity(
      uniqueId: 1,
      calendarDateTime: DateTime(2025, 1, 1),
      memoMadeDateTime: DateTime(2025, 1, 1, 10, 30),
      memoModifiedDateTime: DateTime(2025, 1, 1, 10, 30),
      title: 'Test',
      content: 'Content',
    ),
  ];

  test('delegates to repository.fetchAllMemos', () async {
    when(() => repository.fetchAllMemos())
        .thenAnswer((_) async => Success(memos));

    final result = await useCase();

    expect(result.isSuccess, isTrue);
    expect(result.dataOrNull, memos);
    verify(() => repository.fetchAllMemos()).called(1);
  });

  test('returns ErrorResult when repository fails', () async {
    when(() => repository.fetchAllMemos()).thenAnswer(
      (_) async =>
          const ErrorResult(LocalStorageFailure(message: 'db error')),
    );

    final result = await useCase();

    expect(result.isError, isTrue);
    expect(result.failureOrNull, isA<LocalStorageFailure>());
  });
}
