import 'package:apps.daily_memo/data/entity/add_memo_entity.dart';
import 'package:apps.daily_memo/data/entity/saved_memo_entity.dart';
import 'package:apps.daily_memo/data/mapper/saved_memo_entity_mapper.dart';
import 'package:apps.daily_memo/data/sql_helper.dart';
import 'package:apps.daily_memo/domain/model/home/memo_info.dart';
import 'package:apps.daily_memo/domain/model/home/memo_info_list.dart';
import 'package:apps.daily_memo/domain/repository_interface/memo/memo_repository.dart';

class MemoRepositoryImpl extends MemoRepository {
  @override
  Future<MemoInfoList> get getAllMemoInfo async {
    final List<SavedMemoEntity> memoEntities = await SQLHelper.getItems();

    return MemoInfoList(
        values: memoEntities.map((e) => e.transferToMemoInfo!).toList());
  }

  @override
  Future<MemoInfo?> getMemoInfoById(int memoId) async {
    final List<SavedMemoEntity> memoEntities = await SQLHelper.getItems();

    return memoEntities
        .firstWhere((e) => e.memoId == memoId)
        .transferToMemoInfo;
  }

  @override
  Future<bool> addMemo({
    required String title,
    required String content,
  }) async {
    final int result = await SQLHelper.createItem(
      AddMemoEntity(
          title: title,
          content: content,
          madeDateTime: DateTime.now().toString(),
          modifiedDateTime: DateTime.now().toString()),
    );
    return result == -1 ? false : true;
  }

  Future<MemoInfo?> modifyMemo({
    required int memoId,
    required String title,
    required String content,
    required String madeDateTime,
  }) async {
    final SavedMemoEntity entity = SavedMemoEntity(
      memoId: memoId,
      title: title,
      content: content,
      madeDateTime: madeDateTime,
      modifiedDateTime: DateTime.now().toString(),
    );
    final int result = await SQLHelper.updateItem(entity);
    return result == -1 ? null : entity.transferToMemoInfo;
  }

  @override
  Future<bool> deleteMemo(int memoId) async {
    return await SQLHelper.deleteItem(memoId);
  }
}
