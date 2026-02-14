import 'package:apps.daily_memo/features/memo/data/datasources/memo_local_data_source.dart';
import 'package:apps.daily_memo/features/memo/data/exceptions/external_exception.dart';
import 'package:apps.daily_memo/features/memo/data/repositories/memo_repository_impl.dart';
import 'package:apps.daily_memo/features/memo/domain/entities/memo_info_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/utils.dart';

class MockMemoLocalDataSource extends Mock implements MemoLocalDataSource {}

void main() {
  late MockMemoLocalDataSource dataSource;
  late MemoRepositoryImpl repository;

  setUp(() {
    dataSource = MockMemoLocalDataSource();
    repository = MemoRepositoryImpl(dataSource);
  });

  final rawMemo = <String, Object?>{
    'memoId': 1,
    'title': 'Test Memo',
    'content': 'Test Content',
    'madeDateTime': '2025-01-15 10:30:00',
    'modifiedDateTime': '2025-01-15 10:30:00',
  };

  group('fetchAllMemos', () {
    test('returns list of MemoInfoEntity on success', () async {
      when(() => dataSource.fetchAll())
          .thenAnswer((_) async => Success([rawMemo]));

      final result = await repository.fetchAllMemos();

      expect(result.isSuccess, isTrue);
      final memos = result.dataOrNull!;
      expect(memos.length, 1);
      expect(memos.first.title, 'Test Memo');
      expect(memos.first.uniqueId, 1);
    });

    test('filters out items with null required fields', () async {
      final incompleteMemo = <String, Object?>{
        'memoId': 2,
        'title': null,
        'content': null,
        'madeDateTime': null,
        'modifiedDateTime': null,
      };
      when(() => dataSource.fetchAll())
          .thenAnswer((_) async => Success([rawMemo, incompleteMemo]));

      final result = await repository.fetchAllMemos();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull!.length, 1);
    });

    test('returns ErrorResult with LocalStorageFailure on datasource error',
        () async {
      when(() => dataSource.fetchAll()).thenAnswer(
        (_) async => const ErrorResult(
          LocalStorageExternalException(message: 'db read error'),
        ),
      );

      final result = await repository.fetchAllMemos();

      expect(result.isError, isTrue);
      expect(result.failureOrNull, isA<LocalStorageFailure>());
    });
  });

  group('fetchMemoById', () {
    test('returns MemoInfoEntity when found', () async {
      when(() => dataSource.fetchById(1))
          .thenAnswer((_) async => Success([rawMemo]));

      final result = await repository.fetchMemoById(1);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isA<MemoInfoEntity>());
      expect(result.dataOrNull!.uniqueId, 1);
    });

    test('returns null when not found', () async {
      when(() => dataSource.fetchById(99))
          .thenAnswer((_) async => const Success([]));

      final result = await repository.fetchMemoById(99);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isNull);
    });

    test('returns ErrorResult on datasource error', () async {
      when(() => dataSource.fetchById(any())).thenAnswer(
        (_) async => const ErrorResult(
          LocalStorageExternalException(message: 'query failed'),
        ),
      );

      final result = await repository.fetchMemoById(1);

      expect(result.isError, isTrue);
      expect(result.failureOrNull, isA<LocalStorageFailure>());
    });
  });

  group('addMemo', () {
    test('returns Success(true) on successful insert', () async {
      when(() => dataSource.insert(any()))
          .thenAnswer((_) async => const Success(null));

      final result =
          await repository.addMemo(title: 'New', content: 'Content');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, true);
      verify(() => dataSource.insert(any())).called(1);
    });

    test('returns ErrorResult on insert failure', () async {
      when(() => dataSource.insert(any())).thenAnswer(
        (_) async => const ErrorResult(
          LocalStorageExternalException(message: 'insert error'),
        ),
      );

      final result =
          await repository.addMemo(title: 'T', content: 'C');

      expect(result.isError, isTrue);
      expect(result.failureOrNull, isA<LocalStorageFailure>());
    });
  });

  group('modifyMemo', () {
    test('returns Success(true) on successful update', () async {
      when(() => dataSource.update(any(), any()))
          .thenAnswer((_) async => const Success(null));

      final result = await repository.modifyMemo(
        memoId: 1,
        title: 'Updated',
        content: 'Updated Content',
        madeDateTime: '2025-01-15 10:30:00',
      );

      expect(result.isSuccess, isTrue);
      verify(() => dataSource.update(1, any())).called(1);
    });

    test('returns ErrorResult on update failure', () async {
      when(() => dataSource.update(any(), any())).thenAnswer(
        (_) async => const ErrorResult(
          LocalStorageExternalException(message: 'update error'),
        ),
      );

      final result = await repository.modifyMemo(
        memoId: 1,
        title: 'T',
        content: 'C',
        madeDateTime: '2025-01-15',
      );

      expect(result.isError, isTrue);
    });
  });

  group('deleteMemo', () {
    test('returns Success(true) on successful delete', () async {
      when(() => dataSource.delete(any()))
          .thenAnswer((_) async => const Success(null));

      final result = await repository.deleteMemo(1);

      expect(result.isSuccess, isTrue);
      verify(() => dataSource.delete(1)).called(1);
    });

    test('returns ErrorResult on delete failure', () async {
      when(() => dataSource.delete(any())).thenAnswer(
        (_) async => const ErrorResult(
          LocalStorageExternalException(message: 'delete error'),
        ),
      );

      final result = await repository.deleteMemo(1);

      expect(result.isError, isTrue);
    });
  });
}
