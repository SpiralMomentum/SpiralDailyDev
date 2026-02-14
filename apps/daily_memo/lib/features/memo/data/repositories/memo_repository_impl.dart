import 'package:app_logging/app_logging.dart';
import 'package:apps.daily_memo/features/memo/data/mappers/model_to_entity_mapper.dart';
import 'package:apps.daily_memo/features/memo/data/models/add_memo_model.dart';
import 'package:apps.daily_memo/features/memo/data/models/saved_memo_model.dart';
import 'package:apps.daily_memo/features/memo/data/datasources/memo_local_data_source.dart';
import 'package:apps.daily_memo/features/memo/data/exceptions/external_exception.dart';
import 'package:apps.daily_memo/features/memo/domain/entities/memo_info_entity.dart';
import 'package:apps.daily_memo/features/memo/domain/repositories/memo_repository.dart';
import 'package:utils/utils.dart';

final _logger = AppLogger(tag: 'MemoRepository');

class MemoRepositoryImpl extends MemoRepository {
  final MemoLocalDataSource _localDataSource;

  MemoRepositoryImpl(this._localDataSource);

  @override
  Future<Result<List<MemoInfoEntity>>> fetchAllMemos() async {
    final itemsResult = await _localDataSource.fetchAll();
    if (itemsResult is ErrorResult<List<Map<String, Object?>>>) {
      return ErrorResult(_mapExternalFailure(itemsResult.failure));
    }
    final items = (itemsResult as Success<List<Map<String, Object?>>>).data;
    final memoModels = items
        .map((item) => SavedMemoModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    return Success(
      memoModels
          .map((model) => model.transferToMemoInfo)
          .whereType<MemoInfoEntity>()
          .toList(),
    );
  }

  @override
  Future<Result<MemoInfoEntity?>> fetchMemoById(int memoId) async {
    final itemsResult = await _localDataSource.fetchById(memoId);
    if (itemsResult is ErrorResult<List<Map<String, Object?>>>) {
      return ErrorResult(_mapExternalFailure(itemsResult.failure));
    }
    final items = (itemsResult as Success<List<Map<String, Object?>>>).data;
    if (items.isEmpty) {
      return const Success(null);
    }
    final item = items.first;
    final savedModel =
        SavedMemoModel.fromJson(Map<String, dynamic>.from(item));
    return Success(savedModel.transferToMemoInfo);
  }

  @override
  Future<Result<bool>> addMemo({
    required String title,
    required String content,
  }) async {
    final param = AddMemoModel(
      title: title,
      content: content,
      madeDateTime: DateTime.now().toString(),
      modifiedDateTime: DateTime.now().toString(),
    );
    final result = await _localDataSource.insert(param.toJson());
    if (result is ErrorResult<void>) {
      return ErrorResult(_mapExternalFailure(result.failure));
    }
    return const Success(true);
  }

  @override
  Future<Result<bool>> modifyMemo({
    required int memoId,
    required String title,
    required String content,
    required String madeDateTime,
  }) async {
    final param = SavedMemoModel(
      memoId: memoId,
      title: title,
      content: content,
      madeDateTime: madeDateTime,
      modifiedDateTime: DateTime.now().toString(),
    );
    final result = await _localDataSource.update(memoId, param.toJson());
    if (result is ErrorResult<void>) {
      return ErrorResult(_mapExternalFailure(result.failure));
    }
    return const Success(true);
  }

  @override
  Future<Result<bool>> deleteMemo(int memoId) async {
    final result = await _localDataSource.delete(memoId);
    if (result is ErrorResult<void>) {
      return ErrorResult(_mapExternalFailure(result.failure));
    }
    return const Success(true);
  }

  Failure _mapExternalFailure(Failure error) {
    final failure = error is LocalStorageExternalException
        ? LocalStorageFailure(
            message: error.message ?? '메모 저장소에 접근할 수 없습니다.',
            cause: error.cause ?? error,
            stackTrace: error.stackTrace,
          )
        : LocalStorageFailure(
            message: '메모 저장소에 접근할 수 없습니다.',
            cause: error,
            stackTrace: error.stackTrace,
          );

    _logger.error(
      failure.message ?? 'Unknown storage error',
      error: failure.cause,
      stackTrace: failure.stackTrace,
    );

    return failure;
  }
}
