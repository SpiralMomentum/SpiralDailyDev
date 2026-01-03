import 'package:apps.daily_memo/features/memo/domain/entities/memo_info_entity.dart';
import 'package:apps.daily_memo/features/memo/domain/repositories/memo_repository.dart';
import 'package:utils/utils.dart';

class GetAllMemosUseCase {
  const GetAllMemosUseCase({required MemoRepository repository})
      : _repository = repository;

  final MemoRepository _repository;

  Future<Result<List<MemoInfoEntity>>> call() {
    return _repository.fetchAllMemos();
  }
}
