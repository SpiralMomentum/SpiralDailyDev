import 'package:apps.daily_memo/features/memo/domain/repositories/memo_repository.dart';
import 'package:utils/utils.dart';

class UpdateMemoUseCase {
  const UpdateMemoUseCase({required MemoRepository repository})
      : _repository = repository;

  final MemoRepository _repository;

  Future<Result<bool>> call({
    required int memoId,
    required String title,
    required String content,
    required String madeDateTime,
  }) {
    return _repository.modifyMemo(
      memoId: memoId,
      title: title,
      content: content,
      madeDateTime: madeDateTime,
    );
  }
}
