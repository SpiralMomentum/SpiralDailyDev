import 'package:utils/result/result.dart';

import '../entities/bookmark.dart';
import '../repositories/bookmark_repository.dart';

class GetBookmarks {
  const GetBookmarks(this._repository);

  final BookmarkRepository _repository;

  Future<Result<List<Bookmark>>> call() {
    return _repository.getBookmarks();
  }
}
