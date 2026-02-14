import 'package:apps.daily_memo/features/memo/domain/entities/memo_info_entity.dart';
import 'package:apps.daily_memo/features/memo/domain/repositories/memo_repository.dart';
import 'package:apps.daily_memo/features/memo/domain/usecases/get_memo_by_id_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/utils.dart';

class MockMemoRepository extends Mock implements MemoRepository {}

void main() {
  late MockMemoRepository repository;
  late GetMemoByIdUseCase useCase;

  setUp(() {
    repository = MockMemoRepository();
    useCase = GetMemoByIdUseCase(repository: repository);
  });

  final memo = MemoInfoEntity(
    uniqueId: 5,
    calendarDateTime: DateTime(2025, 3, 15),
    memoMadeDateTime: DateTime(2025, 3, 15, 9, 0),
    memoModifiedDateTime: DateTime(2025, 3, 15, 9, 0),
    title: 'Found Memo',
    content: 'Detail',
  );

  test('returns memo when found', () async {
    when(() => repository.fetchMemoById(5))
        .thenAnswer((_) async => Success(memo));

    final result = await useCase(5);

    expect(result.isSuccess, isTrue);
    expect(result.dataOrNull, memo);
    verify(() => repository.fetchMemoById(5)).called(1);
  });

  test('returns null when not found', () async {
    when(() => repository.fetchMemoById(99))
        .thenAnswer((_) async => const Success(null));

    final result = await useCase(99);

    expect(result.isSuccess, isTrue);
    expect(result.dataOrNull, isNull);
  });

  test('returns ErrorResult when repository fails', () async {
    when(() => repository.fetchMemoById(any())).thenAnswer(
      (_) async =>
          const ErrorResult(LocalStorageFailure(message: 'read error')),
    );

    final result = await useCase(1);

    expect(result.isError, isTrue);
  });
}
