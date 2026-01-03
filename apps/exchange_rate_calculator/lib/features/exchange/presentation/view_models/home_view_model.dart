import 'package:flutter/foundation.dart';

import 'package:exchange_rate_calculator/features/exchange/domain/entities/exchange_info.dart';
import 'package:exchange_rate_calculator/features/exchange/domain/repositories/exchange_repository.dart';
import 'package:exchange_rate_calculator/features/exchange/domain/usecases/get_exchange_info_use_case.dart';
import 'package:exchange_rate_calculator/features/exchange/domain/usecases/load_exchange_info_use_case.dart';
import 'package:utils/utils.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required GetExchangeInfoUseCase getExchangeInfoUseCase,
    required LoadExchangeInfoUseCase loadExchangeInfoUseCase,
  })  : _getExchangeInfoUseCase = getExchangeInfoUseCase,
        _loadExchangeInfoUseCase = loadExchangeInfoUseCase;

  final GetExchangeInfoUseCase _getExchangeInfoUseCase;
  final LoadExchangeInfoUseCase _loadExchangeInfoUseCase;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ExchangeCountry> get enableCountries => ExchangeCountry.values;

  Future<void> load() async {
    _setLoading(true);
    final result = await _loadExchangeInfoUseCase();
    result.when(
      success: (_) => _setError(null),
      error: (failure) => _setError(
        failure.message ?? '환율 정보를 불러오지 못했습니다.',
      ),
    );
    _setLoading(false);
  }

  Result<ExchangeInfo> getExchangeInfo(ExchangeCountry exchangeCountry) {
    return _getExchangeInfoUseCase(exchangeCountry);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }
}
