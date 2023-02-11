import 'package:apps.daily_memo/domain/model/home/memo_list_item.dart';
import 'package:apps.daily_memo/domain/model/memo/add_memo_model.dart';
import 'package:apps.daily_memo/domain/model/memo/modify_memo_model.dart';

abstract class MemoRepository {
  Future<List<MemoListItem>> get getMemoList;
  Future<MemoListItem> getMemoById (int memoId);

  Future<AddMemoModel> addMemo(AddMemoModel memoModel);
  Future<ModifyMemoModel> modifyMemo(ModifyMemoModel memoModel);

  Future<bool> deleteMemo(int memoId);
}
