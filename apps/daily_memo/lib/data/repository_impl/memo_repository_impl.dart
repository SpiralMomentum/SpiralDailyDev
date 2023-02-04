import 'package:apps.daily_memo/data/sql_helper.dart';
import 'package:apps.daily_memo/data/entity/memo_entiry.dart';
import 'package:apps.daily_memo/domain/model/home/memo_list_item.dart';
import 'package:apps.daily_memo/domain/model/memo/memo_model.dart';
import 'package:apps.daily_memo/domain/repository_interface/memo_repository.dart';

class MemoRepositoryImpl extends MemoRepository {
  @override
  Future<List<MemoListItem>> get getMemoList async {
    final List<MemoEntity> memoEntities = await SQLHelper.getItems();
    return memoEntities.map((e) => _mapperMemoEntityToMemoListItem(e)).toList();
  }

  @override
  Future<MemoModel> addMemo(MemoModel memoModel) async {
    await SQLHelper.createItem(_mapperMemoModelToMemoEntity(memoModel));
    return memoModel;
  }

  // TODO: summary get logic add
  MemoListItem _mapperMemoEntityToMemoListItem(MemoEntity memoEntity) {
    return MemoListItem(
      title: memoEntity.title ?? '',
      summaryHeaderContent: memoEntity.content ?? "",
      summaryFooterContent: memoEntity.content ?? "",
      madeDateTime: memoEntity.madeDateTime ?? "",
      modifiedDateTime: memoEntity.modifiedDateTime ?? "",
    );
  }

  // TODO: made date time, modified date time add
  MemoEntity _mapperMemoModelToMemoEntity(MemoModel memoModel) {
    return MemoEntity(
      title: memoModel.title,
      author: "local",
      content: memoModel.content,
      modifiedDateTime: "test",
      madeDateTime: "test",
    );
  }
}
