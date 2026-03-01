import 'package:apps.news_reader/features/bookmarks/domain/usecases/sync_bookmarks.dart';

abstract class BackgroundSyncService {
  Future<void> registerPeriodicSync(
      {Duration interval = const Duration(minutes: 15)});
  Future<void> cancelSync();
  Future<int> executeSyncNow();
}

class MockBackgroundSyncService implements BackgroundSyncService {
  MockBackgroundSyncService({required SyncBookmarks syncBookmarks})
      : _syncBookmarks = syncBookmarks;

  final SyncBookmarks _syncBookmarks;
  bool _isRegistered = false;

  bool get isRegistered => _isRegistered;

  @override
  Future<void> registerPeriodicSync(
      {Duration interval = const Duration(minutes: 15)}) async {
    _isRegistered = true;
  }

  @override
  Future<void> cancelSync() async {
    _isRegistered = false;
  }

  @override
  Future<int> executeSyncNow() async {
    final result = await _syncBookmarks();
    return result.dataOrNull ?? 0;
  }
}
