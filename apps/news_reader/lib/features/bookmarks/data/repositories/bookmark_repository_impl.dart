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
      final data = BookmarkMapper.toMap(bookmark);
      await _localDataSource.insertBookmark(data);
      return Success(bookmark);
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
      await _localDataSource.deleteBookmark(articleId);
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
}
