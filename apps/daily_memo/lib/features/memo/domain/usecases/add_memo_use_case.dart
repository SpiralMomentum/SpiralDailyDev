import 'package:apps.daily_memo/features/memo/domain/repositories/memo_repository.dart';
import 'package:utils/utils.dart';

class AddMemoUseCase {
  const AddMemoUseCase({required MemoRepository repository})
      : _repository = repository;

  final MemoRepository _repository;

  Future<Result<bool>> call({
    required String title,
    required String content,
  }) {
    return _repository.addMemo(title: title, content: content);
  }
}
