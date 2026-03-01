import 'package:dio/dio.dart';
import 'package:exchange_rate_calculator/data/entity/exchange/giuhub/github_exchange_response.dart';
import 'package:retrofit/http.dart';

part 'github_exchange_api_client.g.dart';

@RestApi(
    baseUrl: "https://cdn.jsdelivr.net/gh/fawazahmed0/currency-api@1/latest/currencies/")
abstract class GithubExchangeApiClient {
  factory GithubExchangeApiClient(Dio dio) = _GithubExchangeApiClient;

  @GET("/krw.json")
  Future<GithubExchangeResponse> getAllExchangeInfo();
}


