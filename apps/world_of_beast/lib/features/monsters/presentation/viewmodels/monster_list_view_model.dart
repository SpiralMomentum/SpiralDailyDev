import 'package:flutter/foundation.dart';

import 'package:world_of_beast/core/analytics/analytics_events.dart';
import 'package:app_analytics/app_analytics.dart';

import '../../domain/entities/monster.dart';
import '../../domain/usecases/filter_monsters_by_country_use_case.dart';
import '../../domain/usecases/get_monsters_use_case.dart';

enum ViewMode { list, map }

class MonsterListViewModel extends ChangeNotifier {
  MonsterListViewModel({
    required GetMonstersUseCase getMonsters,
    required FilterMonstersByCountryUseCase filterByCountry,
    Map<String, String>? countryNames,
    AnalyticsTracker? analyticsTracker,
  }) : _getMonsters = getMonsters,
       _filterByCountry = filterByCountry,
       _countryNames = countryNames ?? _defaultCountryNames,
       _analyticsTracker = analyticsTracker;

  final GetMonstersUseCase _getMonsters;
  final FilterMonstersByCountryUseCase _filterByCountry;
  final Map<String, String> _countryNames;
  final AnalyticsTracker? _analyticsTracker;

  bool _isLoading = false;
  String? _errorMessage;
  ViewMode _viewMode = ViewMode.list;
  List<Monster> _allMonsters = const [];
  List<Monster> _visibleMonsters = const [];
  Set<String> _availableCountries = const <String>{};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ViewMode get viewMode => _viewMode;
  List<Monster> get allMonsters => _allMonsters;
  List<Monster> get visibleMonsters => _visibleMonsters;
  bool get canToggleView => !_isLoading && _errorMessage == null;
  bool get canInteractWithMap => !_isLoading && _errorMessage == null;
  Set<String> get availableCountries => _availableCountries;

  String get headerTitle {
    return 'All Monsters';
  }

  Future<void> loadMonsters() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final result = await _getMonsters();
    result.when(
      success: (monsters) {
        _allMonsters = monsters;
        _visibleMonsters = monsters;
        _availableCountries = monsters
            .map((monster) => monster.country.toUpperCase())
            .toSet();
      },
      error: (failure) {
        _errorMessage = failure.message ?? 'Failed to load monsters. Please try again.';
        _allMonsters = const [];
        _visibleMonsters = const [];
        _availableCountries = const <String>{};
      },
    );
    _isLoading = false;
    notifyListeners();
  }

  void toggleViewMode() {
    if (!canToggleView) return;
    if (_viewMode == ViewMode.list) {
      _viewMode = ViewMode.map;
    } else {
      _viewMode = ViewMode.list;
      _visibleMonsters = _allMonsters;
    }
    _analyticsTracker?.trackEvent(
      AnalyticsEvents.viewModeToggled,
      {'mode': _viewMode.name},
    );
    notifyListeners();
  }

  List<Monster> monstersForCountry(String code) {
    final normalized = code.trim().toUpperCase();
    if (!_availableCountries.contains(normalized)) {
      return const [];
    }
    return _filterByCountry(_allMonsters, normalized);
  }

  String titleForCountry(String code, {String? fallbackName}) {
    final normalized = code.trim().toUpperCase();
    final displayName = fallbackName ?? resolveCountryName(normalized);
    return '$displayName Monsters';
  }

  void retry() {
    loadMonsters();
  }

  String resolveCountryName(String code) {
    return _countryNames[code.toUpperCase()] ?? code.toUpperCase();
  }
}

const Map<String, String> _defaultCountryNames = {
  'KR': 'South Korea',
  'JP': 'Japan',
  'US': 'United States',
  'BR': 'Brazil',
  'FR': 'France',
  'EG': 'Egypt',
  'MX': 'Mexico',
  'GR': 'Greece',
  'CN': 'China',
  'NG': 'Nigeria',
  'GB': 'United Kingdom',
  'DE': 'Germany',
  'FI': 'Finland',
  'NO': 'Norway',
  'IT': 'Italy',
  'IN': 'India',
  'ID': 'Indonesia',
  'RU': 'Russia',
  'TH': 'Thailand',
  'VN': 'Vietnam',
};
