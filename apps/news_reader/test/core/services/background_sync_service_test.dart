import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/result/result.dart';

import 'package:apps.news_reader/features/bookmarks/domain/usecases/sync_bookmarks.dart';
import 'package:apps.news_reader/features/bookmarks/domain/repositories/bookmark_repository.dart';
import 'package:apps.news_reader/core/services/background_sync_service.dart';

class MockBookmarkRepository extends Mock implements BookmarkRepository {}

void main() {
  group('MockBackgroundSyncService', () {
    late MockBookmarkRepository mockRepo;
    late SyncBookmarks syncBookmarks;
    late MockBackgroundSyncService service;

    setUp(() {
      mockRepo = MockBookmarkRepository();
      syncBookmarks = SyncBookmarks(mockRepo);
      service = MockBackgroundSyncService(syncBookmarks: syncBookmarks);
    });

    test('registers and cancels periodic sync', () async {
      expect(service.isRegistered, false);
      await service.registerPeriodicSync();
      expect(service.isRegistered, true);
      await service.cancelSync();
      expect(service.isRegistered, false);
    });

    test('executeSyncNow delegates to SyncBookmarks', () async {
      when(() => mockRepo.syncBookmarks())
          .thenAnswer((_) async => const Success(3));
      final count = await service.executeSyncNow();
      expect(count, 3);
      verify(() => mockRepo.syncBookmarks()).called(1);
    });
  });
}
