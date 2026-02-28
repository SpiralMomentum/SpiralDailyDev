abstract class SearchHistoryDataSource {
  Future<List<Map<String, dynamic>>> getSearchHistory();

  Future<void> saveSearchQuery(Map<String, dynamic> queryData);

  Future<void> clearSearchHistory();
}
