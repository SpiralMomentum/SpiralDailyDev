import 'package:utils/utils.dart';

import 'package:spiral_trade_show/features/info_shelf/models/model/trades.dart';

abstract class InfoShelfRemoteDataSource {
  Future<Result<Trades>> fetchInfo({
    required int startIndex,
    required int endIndex,
  });
}
