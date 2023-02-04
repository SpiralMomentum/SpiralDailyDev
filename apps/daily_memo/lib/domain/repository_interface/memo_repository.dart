import 'package:apps.daily_memo/domain/model/home/memo_list_item.dart';

abstract class MemoRepository{
  Future<List<MemoListItem>> get getMemoList;
}