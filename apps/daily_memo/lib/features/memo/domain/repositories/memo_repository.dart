import 'package:apps.daily_memo/features/memo/domain/entities/memo_info_entity.dart';
import 'package:utils/utils.dart';

abstract class MemoRepository {
  const MemoRepository();

  Future<Result<List<MemoInfoEntity>>> fetchAllMemos();

  Future<Result<MemoInfoEntity?>> fetchMemoById(int memoId);

  Future<Result<bool>> addMemo({
    required String title,
    required String content,
  });

  Future<Result<bool>> modifyMemo({
    required int memoId,
    required String title,
    required String content,
    required String madeDateTime,
  });

  Future<Result<bool>> deleteMemo(int memoId);
}
