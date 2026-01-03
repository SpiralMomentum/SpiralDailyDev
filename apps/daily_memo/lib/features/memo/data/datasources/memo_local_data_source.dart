import 'package:utils/utils.dart';

abstract class MemoLocalDataSource {
  Future<Result<List<Map<String, Object?>>>> fetchAll();

  Future<Result<List<Map<String, Object?>>>> fetchById(int memoId);

  Future<Result<void>> insert(Map<String, Object?> payload);

  Future<Result<void>> update(int memoId, Map<String, Object?> payload);

  Future<Result<void>> delete(int memoId);
}
