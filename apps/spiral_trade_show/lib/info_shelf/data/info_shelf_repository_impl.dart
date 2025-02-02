import 'package:dio/dio.dart';
import 'package:spiral_trade_show/info_shelf/domain/info_shelf_repository.dart';
import 'package:spiral_trade_show/info_shelf/model/trades.dart';
import 'package:ui_components/card/info.dart';

class InfoShelfRepositoryImpl implements InfoShelfRepository {
  final Dio _dio;
  final String baseUrl;
  final String serviceKey;
  final String format;
  final String serviceName;

  InfoShelfRepositoryImpl(
    this._dio, {
    required this.baseUrl,
    required this.serviceKey,
    required this.format,
    required this.serviceName,
  });

  @override
  Future<List<Info>> fetchInfo(
    int startIndex,
    int endIndex,
  ) async {
    final options = Options(
      responseType: ResponseType.json,
    );
    try {
      final result = await _dio.get(
        '$baseUrl/$serviceKey/$format/$serviceName/$startIndex/$endIndex/',
        options: options,
      );
      final Trades value = Trades.fromJson(result.data!);
      return value.tradeShowInfo.showDataList
          .map((e) => e.toDomainEntity())
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
