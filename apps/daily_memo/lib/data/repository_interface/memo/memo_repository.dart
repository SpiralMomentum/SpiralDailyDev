import 'package:apps.daily_memo/domain/entity/memo/memo_info_entity.dart';

abstract class MemoRepository {
  MemoRepository();

  Future<List<MemoInfoEntity>> get getAllMemoInfo;

  Future<MemoInfoEntity?> getMemoInfoById(int memoId);

  Future<bool> addMemo({
    required String title,
    required String content,
  });

  Future<bool> modifyMemo({
    required int memoId,
    required String title,
    required String content,
    required String madeDateTime,
  });

  Future<bool> deleteMemo(int memoId);
}
