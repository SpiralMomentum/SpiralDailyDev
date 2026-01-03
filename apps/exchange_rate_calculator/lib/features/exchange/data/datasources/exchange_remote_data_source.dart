import 'package:utils/utils.dart';

import '../models/github_exchange_response.dart';

abstract class ExchangeRemoteDataSource {
  Future<Result<GithubExchangeResponse>> fetchGithubExchange();
}
