import 'package:apps.daily_memo/features/memo/domain/repositories/memo_repository.dart';
import 'package:apps.daily_memo/features/memo/domain/usecases/delete_memo_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/utils.dart';

class MockMemoRepository extends Mock implements MemoRepository {}

void main() {
  late MockMemoRepository repository;
  late DeleteMemoUseCase useCase;

  setUp(() {
    repository = MockMemoRepository();
    useCase = DeleteMemoUseCase(repository: repository);
  });

  test('delegates to repository.deleteMemo with memoId', () async {
    when(() => repository.deleteMemo(any()))
        .thenAnswer((_) async => const Success(true));

    final result = await useCase(42);

    expect(result.isSuccess, isTrue);
    verify(() => repository.deleteMemo(42)).called(1);
  });

  test('returns ErrorResult when repository fails', () async {
    when(() => repository.deleteMemo(any())).thenAnswer(
      (_) async =>
          const ErrorResult(LocalStorageFailure(message: 'delete failed')),
    );

    final result = await useCase(1);

    expect(result.isError, isTrue);
  });
}
