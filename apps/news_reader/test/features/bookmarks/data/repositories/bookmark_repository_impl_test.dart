import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/result/result.dart';
import 'package:utils/result/failure.dart';
import 'package:apps.news_reader/features/bookmarks/data/datasources/bookmark_local_data_source.dart';
import 'package:apps.news_reader/features/bookmarks/data/repositories/bookmark_repository_impl.dart';
import 'package:apps.news_reader/features/bookmarks/domain/entities/bookmark.dart';

class MockBookmarkLocalDataSource extends Mock
    implements BookmarkLocalDataSource {}

void main() {
  late BookmarkRepositoryImpl repository;
  late MockBookmarkLocalDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockBookmarkLocalDataSource();
    repository = BookmarkRepositoryImpl(localDataSource: mockDataSource);
  });

  final tBookmarkRow = {
    'article_id': 'art-1',
    'title': 'Test Title',
    'summary': 'Summary',
    'content': 'Content',
    'image_url': 'https://img.com/1.jpg',
    'category': 'technology',
    'saved_at': 1704067200000,
    'sync_status': 'pendingUpload',
    'version': 1,
    'created_at': 1704067200000,
    'updated_at': 1704067200000,
  };

  final tPendingDeleteRow = {
    'article_id': 'art-2',
    'title': 'Deleted Article',
    'summary': 'Summary 2',
    'content': 'Content 2',
    'image_url': 'https://img.com/2.jpg',
    'category': 'science',
    'saved_at': 1704067200000,
    'sync_status': 'pendingDelete',
    'version': 1,
    'created_at': 1704067200000,
    'updated_at': 1704067200000,
  };

  group('BookmarkRepositoryImpl', () {
    group('removeBookmark (soft delete)', () {
      test('calls updateSyncStatus with pendingDelete instead of delete',
          () async {
        when(() => mockDataSource.updateSyncStatus(
              'art-1',
              'pendingDelete',
              1,
            )).thenAnswer((_) async {});

        final result = await repository.removeBookmark('art-1');

        expect(result, isA<Success<void>>());
        verify(() => mockDataSource.updateSyncStatus(
              'art-1',
              'pendingDelete',
              1,
            )).called(1);
        verifyNever(() => mockDataSource.deleteBookmark(any()));
      });

      test('returns ErrorResult when updateSyncStatus throws', () async {
        when(() => mockDataSource.updateSyncStatus(
              'art-1',
              'pendingDelete',
              1,
            )).thenThrow(Exception('DB error'));

        final result = await repository.removeBookmark('art-1');

        expect(result, isA<ErrorResult<void>>());
        final error = result as ErrorResult<void>;
        expect(error.failure, isA<LocalStorageFailure>());
      });
    });

    group('addBookmark', () {
      test('sets sync_status to pendingUpload', () async {
        when(() => mockDataSource.insertBookmark(any()))
            .thenAnswer((_) async {});

        final bookmark = Bookmark(
          articleId: 'art-1',
          title: 'Test',
          summary: 'Summary',
          content: 'Content',
          imageUrl: 'url',
          category: 'technology',
          savedAt: DateTime(2024, 1, 1),
          syncStatus: SyncStatus.synced,
        );

        final result = await repository.addBookmark(bookmark);

        expect(result, isA<Success<Bookmark>>());
        final success = result as Success<Bookmark>;
        expect(success.data.syncStatus, SyncStatus.pendingUpload);

        final captured =
            verify(() => mockDataSource.insertBookmark(captureAny()))
                .captured
                .single as Map<String, dynamic>;
        expect(captured['sync_status'], 'pendingUpload');
      });
    });

    group('getPendingBookmarks', () {
      test('returns list of pending bookmarks', () async {
        when(() => mockDataSource.getPendingBookmarks())
            .thenAnswer((_) async => [tBookmarkRow, tPendingDeleteRow]);

        final result = await repository.getPendingBookmarks();

        expect(result, isA<Success<List<Bookmark>>>());
        final success = result as Success<List<Bookmark>>;
        expect(success.data, hasLength(2));
        expect(success.data[0].syncStatus, SyncStatus.pendingUpload);
        expect(success.data[1].syncStatus, SyncStatus.pendingDelete);
      });

      test('returns ErrorResult when data source throws', () async {
        when(() => mockDataSource.getPendingBookmarks())
            .thenThrow(Exception('DB error'));

        final result = await repository.getPendingBookmarks();

        expect(result, isA<ErrorResult<List<Bookmark>>>());
      });
    });

    group('syncBookmarks', () {
      test(
          'deletes pendingDelete and updates pendingUpload to synced, returns count',
          () async {
        when(() => mockDataSource.getPendingBookmarks())
            .thenAnswer((_) async => [tBookmarkRow, tPendingDeleteRow]);
        when(() => mockDataSource.updateSyncStatus('art-1', 'synced', 1))
            .thenAnswer((_) async {});
        when(() => mockDataSource.deleteBookmark('art-2'))
            .thenAnswer((_) async {});

        final result = await repository.syncBookmarks();

        expect(result, isA<Success<int>>());
        final success = result as Success<int>;
        expect(success.data, 2);
        verify(() => mockDataSource.updateSyncStatus('art-1', 'synced', 1))
            .called(1);
        verify(() => mockDataSource.deleteBookmark('art-2')).called(1);
      });

      test('returns 0 when no pending bookmarks', () async {
        when(() => mockDataSource.getPendingBookmarks())
            .thenAnswer((_) async => []);

        final result = await repository.syncBookmarks();

        expect(result, isA<Success<int>>());
        final success = result as Success<int>;
        expect(success.data, 0);
      });

      test('returns ErrorResult when data source throws', () async {
        when(() => mockDataSource.getPendingBookmarks())
            .thenThrow(Exception('DB error'));

        final result = await repository.syncBookmarks();

        expect(result, isA<ErrorResult<int>>());
      });
    });

    group('updateSyncStatus', () {
      test('delegates to data source correctly', () async {
        when(() => mockDataSource.updateSyncStatus('art-1', 'synced', 2))
            .thenAnswer((_) async {});

        final result = await repository.updateSyncStatus(
          'art-1',
          SyncStatus.synced,
          2,
        );

        expect(result, isA<Success<void>>());
        verify(() => mockDataSource.updateSyncStatus('art-1', 'synced', 2))
            .called(1);
      });

      test('returns ErrorResult when data source throws', () async {
        when(() => mockDataSource.updateSyncStatus('art-1', 'synced', 2))
            .thenThrow(Exception('DB error'));

        final result = await repository.updateSyncStatus(
          'art-1',
          SyncStatus.synced,
          2,
        );

        expect(result, isA<ErrorResult<void>>());
      });
    });
  });
}
