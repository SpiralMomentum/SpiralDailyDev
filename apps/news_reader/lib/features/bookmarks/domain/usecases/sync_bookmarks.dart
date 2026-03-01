import 'package:utils/result/result.dart';

import '../repositories/bookmark_repository.dart';

class SyncBookmarks {
  const SyncBookmarks(this._repository);

  final BookmarkRepository _repository;

  Future<Result<int>> call() {
    return _repository.syncBookmarks();
  }
}
