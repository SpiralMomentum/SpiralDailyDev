import 'package:apps.daily_memo/domain/model/home/memo_list_item.dart';
import 'package:apps.daily_memo/domain/model/memo/memo_model.dart';

abstract class MemoRepository {
  Future<List<MemoListItem>> get getMemoList;

  Future<MemoModel> addMemo(MemoModel memoModel);
}
