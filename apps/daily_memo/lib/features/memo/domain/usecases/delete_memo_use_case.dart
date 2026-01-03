import 'package:apps.daily_memo/features/memo/domain/repositories/memo_repository.dart';
import 'package:utils/utils.dart';

class DeleteMemoUseCase {
  const DeleteMemoUseCase({required MemoRepository repository})
      : _repository = repository;

  final MemoRepository _repository;

  Future<Result<bool>> call(int memoId) {
    return _repository.deleteMemo(memoId);
  }
}
