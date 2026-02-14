import 'package:apps.daily_memo/features/memo/data/mappers/model_to_entity_mapper.dart';
import 'package:apps.daily_memo/features/memo/data/models/saved_memo_model.dart';
import 'package:apps.daily_memo/features/memo/domain/entities/memo_info_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SavedMemoModel.transferToMemoInfo', () {
    test('returns MemoInfoEntity with valid fields', () {
      final model = SavedMemoModel(
        memoId: 1,
        title: 'Test Title',
        content: 'Test Content',
        madeDateTime: '2025-01-15 10:30:00',
        modifiedDateTime: '2025-01-15 10:30:00',
      );

      final entity = model.transferToMemoInfo;

      expect(entity, isNotNull);
      expect(entity, isA<MemoInfoEntity>());
      expect(entity!.uniqueId, 1);
      expect(entity.title, 'Test Title');
      expect(entity.content, 'Test Content');
    });

    test('returns null when title is null', () {
      final model = SavedMemoModel(
        memoId: 1,
        title: null,
        content: 'Content',
        madeDateTime: '2025-01-15 10:30:00',
        modifiedDateTime: '2025-01-15 10:30:00',
      );

      expect(model.transferToMemoInfo, isNull);
    });

    test('returns null when content is null', () {
      final model = SavedMemoModel(
        memoId: 1,
        title: 'Title',
        content: null,
        madeDateTime: '2025-01-15 10:30:00',
        modifiedDateTime: '2025-01-15 10:30:00',
      );

      expect(model.transferToMemoInfo, isNull);
    });

    test('returns null when madeDateTime is null', () {
      final model = SavedMemoModel(
        memoId: 1,
        title: 'Title',
        content: 'Content',
        madeDateTime: null,
        modifiedDateTime: '2025-01-15 10:30:00',
      );

      expect(model.transferToMemoInfo, isNull);
    });

    test('returns null when modifiedDateTime is null', () {
      final model = SavedMemoModel(
        memoId: 1,
        title: 'Title',
        content: 'Content',
        madeDateTime: '2025-01-15 10:30:00',
        modifiedDateTime: null,
      );

      expect(model.transferToMemoInfo, isNull);
    });

    test('returns null when date format is invalid', () {
      final model = SavedMemoModel(
        memoId: 1,
        title: 'Title',
        content: 'Content',
        madeDateTime: 'not-a-date',
        modifiedDateTime: 'not-a-date',
      );

      expect(model.transferToMemoInfo, isNull);
    });
  });
}
