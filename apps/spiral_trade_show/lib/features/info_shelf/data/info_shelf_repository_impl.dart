import 'package:app_logging/app_logging.dart';
import 'package:spiral_trade_show/features/info_shelf/data/datasources/info_shelf_remote_data_source.dart';
import 'package:spiral_trade_show/features/info_shelf/data/exceptions/external_exception.dart';
import 'package:spiral_trade_show/features/info_shelf/domain/info_shelf_repository.dart';
import 'package:spiral_trade_show/features/info_shelf/models/model/trades.dart';
import 'package:ui_components/card/info.dart';
import 'package:utils/utils.dart';

class InfoShelfRepositoryImpl implements InfoShelfRepository {
  InfoShelfRepositoryImpl(this._remoteDataSource);

  final InfoShelfRemoteDataSource _remoteDataSource;
  final _logger = AppLogger(tag: 'InfoShelfRepository');

  @override
  Future<Result<List<Info>>> fetchInfo(
    int startIndex,
    int endIndex,
  ) async {
    final result = await _remoteDataSource.fetchInfo(
      startIndex: startIndex,
      endIndex: endIndex,
    );
    if (result is ErrorResult<Trades>) {
      return ErrorResult(_mapExternalFailure(result.failure));
    }
    final value = (result as Success<Trades>).data;
    return Success(
      value.tradeShowInfo.showDataList
          .map((e) => e.toDomainEntity())
          .toList(),
    );
  }

  Failure _mapExternalFailure(Failure error) {
    if (error is NetworkExternalException) {
      _logger.warning(
        'NetworkExternalException -> NetworkFailure 매핑 [${error.type.name}]: ${error.message}',
        error: error.cause,
        stackTrace: error.stackTrace,
      );
      return NetworkFailure(
        message: error.message ?? '전시 정보를 불러오지 못했습니다.',
        cause: error.cause ?? error,
        stackTrace: error.stackTrace,
      );
    }
    _logger.warning(
      'ExternalException -> NetworkFailure 매핑: ${error.message}',
      error: error.cause,
      stackTrace: error.stackTrace,
    );
    return NetworkFailure(
      message: '전시 정보를 불러오지 못했습니다.',
      cause: error,
      stackTrace: error.stackTrace,
    );
  }
}
