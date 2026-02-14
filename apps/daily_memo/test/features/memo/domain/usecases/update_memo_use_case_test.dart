import 'package:apps.daily_memo/features/memo/domain/repositories/memo_repository.dart';
import 'package:apps.daily_memo/features/memo/domain/usecases/update_memo_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/utils.dart';

class MockMemoRepository extends Mock implements MemoRepository {}

void main() {
  late MockMemoRepository repository;
  late UpdateMemoUseCase useCase;

  setUp(() {
    repository = MockMemoRepository();
    useCase = UpdateMemoUseCase(repository: repository);
  });

  test('delegates to repository.modifyMemo with correct params', () async {
    when(() => repository.modifyMemo(
          memoId: any(named: 'memoId'),
          title: any(named: 'title'),
          content: any(named: 'content'),
          madeDateTime: any(named: 'madeDateTime'),
        )).thenAnswer((_) async => const Success(true));

    final result = await useCase(
      memoId: 1,
      title: 'Updated',
      content: 'New content',
      madeDateTime: '2025-01-01 10:00:00',
    );

    expect(result.isSuccess, isTrue);
    verify(() => repository.modifyMemo(
          memoId: 1,
          title: 'Updated',
          content: 'New content',
          madeDateTime: '2025-01-01 10:00:00',
        )).called(1);
  });

  test('returns ErrorResult when repository fails', () async {
    when(() => repository.modifyMemo(
          memoId: any(named: 'memoId'),
          title: any(named: 'title'),
          content: any(named: 'content'),
          madeDateTime: any(named: 'madeDateTime'),
        )).thenAnswer(
      (_) async =>
          const ErrorResult(LocalStorageFailure(message: 'update failed')),
    );

    final result = await useCase(
      memoId: 1,
      title: 'T',
      content: 'C',
      madeDateTime: '2025-01-01',
    );

    expect(result.isError, isTrue);
  });
}
