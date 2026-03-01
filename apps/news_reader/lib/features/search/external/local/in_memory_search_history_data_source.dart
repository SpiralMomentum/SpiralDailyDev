import '../../data/datasources/search_history_data_source.dart';

class InMemorySearchHistoryDataSource implements SearchHistoryDataSource {
  final List<Map<String, dynamic>> _history = [];

  @override
  Future<List<Map<String, dynamic>>> getSearchHistory() async {
    return List.unmodifiable(_history.reversed);
  }

  @override
  Future<void> saveSearchQuery(Map<String, dynamic> queryData) async {
    final query = queryData['query'] as String;

    // Remove duplicate if exists
    _history.removeWhere((entry) => entry['query'] == query);

    _history.add(queryData);
  }

  @override
  Future<void> clearSearchHistory() async {
    _history.clear();
  }
}
