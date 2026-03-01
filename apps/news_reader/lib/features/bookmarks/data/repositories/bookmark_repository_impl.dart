import 'package:utils/result/result.dart';
import 'package:utils/result/failure.dart';

import '../../domain/entities/bookmark.dart';
import '../../domain/repositories/bookmark_repository.dart';
import '../datasources/bookmark_local_data_source.dart';
import '../mappers/bookmark_mapper.dart';

class BookmarkRepositoryImpl implements BookmarkRepository {
  const BookmarkRepositoryImpl({
    required BookmarkLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  final BookmarkLocalDataSource _localDataSource;

  @override
  Future<Result<List<Bookmark>>> getBookmarks() async {
    try {
      final rows = await _localDataSource.getBookmarks();
      final bookmarks = rows.map(BookmarkMapper.toDomain).toList();
      return Success(bookmarks);
    } catch (e, st) {
      return ErrorResult(
        LocalStorageFailure(
          message: e.toString(),
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Bookmark>> addBookmark(Bookmark bookmark) async {
    try {
      final bookmarkWithSync = bookmark.copyWith(
        syncStatus: SyncStatus.pendingUpload,
      );
      final data = BookmarkMapper.toMap(bookmarkWithSync);
      await _localDataSource.insertBookmark(data);
      return Success(bookmarkWithSync);
    } catch (e, st) {
      return ErrorResult(
        LocalStorageFailure(
          message: e.toString(),
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> removeBookmark(String articleId) async {
    try {
      await _localDataSource.updateSyncStatus(
        articleId,
        SyncStatus.pendingDelete.name,
        1,
      );
      return const Success(null);
    } catch (e, st) {
      return ErrorResult(
        LocalStorageFailure(
          message: e.toString(),
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<bool>> isBookmarked(String articleId) async {
    try {
      final result = await _localDataSource.isBookmarked(articleId);
      return Success(result);
    } catch (e, st) {
      return ErrorResult(
        LocalStorageFailure(
          message: e.toString(),
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<Bookmark>>> getPendingBookmarks() async {
    try {
      final rows = await _localDataSource.getPendingBookmarks();
      final bookmarks = rows.map(BookmarkMapper.toDomain).toList();
      return Success(bookmarks);
    } catch (e, st) {
      return ErrorResult(
        LocalStorageFailure(
          message: e.toString(),
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<int>> syncBookmarks() async {
    try {
      final rows = await _localDataSource.getPendingBookmarks();
      final pending = rows.map(BookmarkMapper.toDomain).toList();
      var syncedCount = 0;

      for (final bookmark in pending) {
        if (bookmark.syncStatus == SyncStatus.pendingDelete) {
          await _localDataSource.deleteBookmark(bookmark.articleId);
          syncedCount++;
        } else if (bookmark.syncStatus == SyncStatus.pendingUpload) {
          await _localDataSource.updateSyncStatus(
            bookmark.articleId,
            SyncStatus.synced.name,
            1,
          );
          syncedCount++;
        }
      }

      return Success(syncedCount);
    } catch (e, st) {
      return ErrorResult(
        LocalStorageFailure(
          message: e.toString(),
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> updateSyncStatus(
    String articleId,
    SyncStatus status,
    int version,
  ) async {
    try {
      await _localDataSource.updateSyncStatus(
        articleId,
        status.name,
        version,
      );
      return const Success(null);
    } catch (e, st) {
      return ErrorResult(
        LocalStorageFailure(
          message: e.toString(),
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
