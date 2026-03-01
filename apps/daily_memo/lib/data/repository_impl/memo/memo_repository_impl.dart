import 'package:apps.daily_memo/data/mapper/model_to_entity_mapper.dart';
import 'package:apps.daily_memo/data/model/memo/add_memo_model.dart';
import 'package:apps.daily_memo/data/model/memo/saved_memo_model.dart';
import 'package:apps.daily_memo/data/repository_interface/memo/memo_repository.dart';
import 'package:apps.daily_memo/data/sql_helper.dart';
import 'package:apps.daily_memo/domain/entity/memo/memo_info_entity.dart';

class MemoRepositoryImpl extends MemoRepository {
  final DatabaseHelper _databaseHelper;

  MemoRepositoryImpl(this._databaseHelper);

  @override
  Future<List<MemoInfoEntity>> get getAllMemoInfo async {
    try {
      final items = await _databaseHelper.getAllItems();

      final List<SavedMemoModel> memoModels =
          items.map((e) => SavedMemoModel.fromJson(e)).toList();
      final List<MemoInfoEntity?> memoEntities =
          memoModels.map((e) => e.transferToMemoInfo).toList();

      List<MemoInfoEntity> nonNullMemoEntities = [];

      for (MemoInfoEntity? i in memoEntities) {
        if (i != null) nonNullMemoEntities.add(i);
      }

      return nonNullMemoEntities;
    } catch (e) {
      throw Exception(e);
    }
  }

  @override
  Future<MemoInfoEntity?> getMemoInfoById(int memoId) async {
    try {
      final items = await _databaseHelper.getItem(memoId);
      if (items == null || items.isEmpty) return null;

      final SavedMemoModel savedModel = SavedMemoModel.fromJson(items.firstOrNull);

      return savedModel.transferToMemoInfo;
    } catch (e) {
      throw Exception(e);
    }
  }

  @override
  Future<bool> addMemo({
    required String title,
    required String content,
  }) async {
    try {
      final AddMemoModel param = AddMemoModel(
          title: title,
          content: content,
          madeDateTime: DateTime.now().toString(),
          modifiedDateTime: DateTime.now().toString());

      await _databaseHelper.createItem(param);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> modifyMemo({
    required int memoId,
    required String title,
    required String content,
    required String madeDateTime,
  }) async {
    try {
      final SavedMemoModel param = SavedMemoModel(
        memoId: memoId,
        title: title,
        content: content,
        madeDateTime: madeDateTime,
        modifiedDateTime: DateTime.now().toString(),
      );

      await _databaseHelper.updateItem(memoId, param);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> deleteMemo(int memoId) async {
    try {
      await _databaseHelper.removeItem(memoId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
