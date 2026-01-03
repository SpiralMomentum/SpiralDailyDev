import 'package:apps.daily_memo/features/memo/domain/entities/memo_info_entity.dart';
import 'package:apps.daily_memo/features/memo/domain/repositories/memo_repository.dart';
import 'package:utils/utils.dart';

class GetMemoByIdUseCase {
  const GetMemoByIdUseCase({required MemoRepository repository})
      : _repository = repository;

  final MemoRepository _repository;

  Future<Result<MemoInfoEntity?>> call(int memoId) {
    return _repository.fetchMemoById(memoId);
  }
}
