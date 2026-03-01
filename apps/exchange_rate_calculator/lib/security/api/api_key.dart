enum ApiKey{
  KOREA_EXIM_EXCHANGE_API,
}

extension ApiKeyExtension on ApiKey{
  String get key{
    switch(this){
      case ApiKey.KOREA_EXIM_EXCHANGE_API:
        return "please input your api key";
    }
  }
}