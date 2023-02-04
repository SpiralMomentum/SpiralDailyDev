import 'package:apps.daily_memo/data/SQLHelper.dart';
import 'package:apps.daily_memo/data/entity/memo_entiry.dart';
import 'package:apps.daily_memo/domain/model/home/memo_list_item.dart';
import 'package:apps.daily_memo/domain/repository_interface/memo_repository.dart';

class MemoRepositoryImpl extends MemoRepository {
  @override
  Future<List<MemoListItem>> get getMemoList async {
    final List<MemoEntity> memoEntities = await SQLHelper.getItems();
    return memoEntities.map((e) => _mapper(e)).toList();
  }

  MemoListItem _mapper(MemoEntity memoEntity) {
    return MemoListItem(
      title: memoEntity.title ?? '',
      summaryHeaderContent: memoEntity.content ?? "",
      summaryFooterContent: memoEntity.content ?? "",
      madeDateTime: memoEntity.madeDateTime ?? "",
      modifiedDataTime: memoEntity.modifiedDataTime ?? "",
    );
  }
}