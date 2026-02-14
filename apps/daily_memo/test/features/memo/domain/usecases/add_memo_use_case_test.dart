import 'package:apps.daily_memo/features/memo/domain/repositories/memo_repository.dart';
import 'package:apps.daily_memo/features/memo/domain/usecases/add_memo_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/utils.dart';

class MockMemoRepository extends Mock implements MemoRepository {}

void main() {
  late MockMemoRepository repository;
  late AddMemoUseCase useCase;

  setUp(() {
    repository = MockMemoRepository();
    useCase = AddMemoUseCase(repository: repository);
  });

  test('delegates to repository.addMemo with correct params', () async {
    when(() => repository.addMemo(title: any(named: 'title'), content: any(named: 'content')))
        .thenAnswer((_) async => const Success(true));

    final result = await useCase(title: 'Title', content: 'Body');

    expect(result.isSuccess, isTrue);
    expect(result.dataOrNull, true);
    verify(() => repository.addMemo(title: 'Title', content: 'Body')).called(1);
  });

  test('returns ErrorResult when repository fails', () async {
    when(() => repository.addMemo(title: any(named: 'title'), content: any(named: 'content')))
        .thenAnswer(
      (_) async =>
          const ErrorResult(LocalStorageFailure(message: 'insert failed')),
    );

    final result = await useCase(title: 'T', content: 'C');

    expect(result.isError, isTrue);
  });
}
