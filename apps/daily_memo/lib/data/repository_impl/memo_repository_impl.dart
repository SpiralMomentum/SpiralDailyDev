import 'package:apps.daily_memo/data/entity/add_memo_entity.dart';
import 'package:apps.daily_memo/data/entity/saved_memo_entity.dart';
import 'package:apps.daily_memo/data/sql_helper.dart';
import 'package:apps.daily_memo/domain/model/home/memo_list_item.dart';
import 'package:apps.daily_memo/domain/model/memo/add_memo_model.dart';
import 'package:apps.daily_memo/domain/model/memo/modify_memo_model.dart';
import 'package:apps.daily_memo/domain/repository_interface/memo_repository.dart';

class MemoRepositoryImpl extends MemoRepository {
  @override
  Future<List<MemoListItem>> get getMemoList async {
    final List<SavedMemoEntity> memoEntities = await SQLHelper.getItems();
    return memoEntities
        .map((e) => _mapperSavedMemoEntityToMemoListItem(e))
        .toList();
  }

  @override
  Future<AddMemoModel> addMemo(AddMemoModel memoModel) async {
    await SQLHelper.createItem(_mapperMemoModelToAddMemoEntity(memoModel));
    return memoModel;
  }

  Future<ModifyMemoModel> modifyMemo(ModifyMemoModel memoModel) async {
    await SQLHelper.updateItem(_mapperMemoModelToSavedMemoEntity(memoModel));
    return memoModel;
  }

  @override
  Future<bool> deleteMemo(int memoId) async {
    return await SQLHelper.deleteItem(memoId);
  }

  // TODO: summary get logic add
  MemoListItem _mapperSavedMemoEntityToMemoListItem(
      SavedMemoEntity memoEntity) {
    return MemoListItem(
      memoId: memoEntity.memoId,
      title: memoEntity.title ?? '',
      content: memoEntity.content ?? "",
      summaryHeaderContent: memoEntity.content ?? "",
      summaryFooterContent: memoEntity.content ?? "",
      madeDateTime: memoEntity.madeDateTime ?? "",
      modifiedDateTime: memoEntity.modifiedDateTime ?? "",
    );
  }


  // TODO: made date time, modified date time add
  AddMemoEntity _mapperMemoModelToAddMemoEntity(AddMemoModel memoModel) {
    return AddMemoEntity(
      title: memoModel.title,
      author: "local",
      content: memoModel.content,
      modifiedDateTime: "test",
      madeDateTime: "test",
    );
  }

  SavedMemoEntity _mapperMemoModelToSavedMemoEntity(ModifyMemoModel memoModel) {
    return SavedMemoEntity(
      memoId: memoModel.memoId,
      title: memoModel.title,
      author: "local",
      content: memoModel.content,
      modifiedDateTime: "test",
      madeDateTime: "test",
    );
  }

  // TODO: 만약 없을때?
  @override
  Future<MemoListItem> getMemoById(int memoId) async {
    final List<SavedMemoEntity> memoEntities = await SQLHelper.getItems();
    return memoEntities
        .where((element) => element.memoId == memoId)
        .map((e) => _mapperSavedMemoEntityToMemoListItem(e))
        .first;
  }

}
