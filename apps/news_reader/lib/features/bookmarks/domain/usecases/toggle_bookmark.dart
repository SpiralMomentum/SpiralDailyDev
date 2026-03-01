import 'package:utils/result/result.dart';

import 'package:apps.news_reader/features/news_feed/domain/entities/article.dart';
import '../entities/bookmark.dart';
import '../repositories/bookmark_repository.dart';

class ToggleBookmark {
  const ToggleBookmark(this._repository);

  final BookmarkRepository _repository;

  Future<Result<bool>> call(Article article) async {
    final isBookmarkedResult = await _repository.isBookmarked(article.id);

    switch (isBookmarkedResult) {
      case Success(data: final isBookmarked):
        if (isBookmarked) {
          final removeResult = await _repository.removeBookmark(article.id);
          return switch (removeResult) {
            Success() => const Success(false),
            ErrorResult(:final failure) => ErrorResult(failure),
          };
        } else {
          final bookmark = Bookmark(
            articleId: article.id,
            title: article.title,
            summary: article.summary,
            content: article.content,
            imageUrl: article.imageUrl,
            category: article.category.name,
            savedAt: DateTime.now(),
            syncStatus: SyncStatus.pendingUpload,
          );
          final addResult = await _repository.addBookmark(bookmark);
          return switch (addResult) {
            Success() => const Success(true),
            ErrorResult(:final failure) => ErrorResult(failure),
          };
        }
      case ErrorResult(:final failure):
        return ErrorResult(failure);
    }
  }
}
