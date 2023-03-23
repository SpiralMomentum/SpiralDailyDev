import 'package:dio/dio.dart';
import 'package:exchange_rate_calculator/data/entity/exchange/korea_exim/korea_exim_exchange_info_entity.dart';
import 'package:retrofit/retrofit.dart';

part 'korea_exim_exchange_api_client.g.dart';
/* TODO: Adapter Pattern
*  기존에 사용하고 있던 환율을 가져오는 동작을 수행하는 클라이언트
* */
@RestApi(
    baseUrl: "https://www.koreaexim.go.kr/site/program/financial")
abstract class KoreaEximExchangeApiClient {
  factory KoreaEximExchangeApiClient(Dio dio) = _KoreaEximExchangeApiClient;

  @GET("/exchangeJSON")
  Future<List<KoreaEximExchangeInfoEntity>> getAllExchangeInfo(
      @Query("authkey") String apiKey,
      @Query("searchdate") String searchDate,
      @Query("data") String dataType,
      );
}

