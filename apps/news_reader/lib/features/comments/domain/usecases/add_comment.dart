import 'package:utils/result/result.dart';

import '../entities/comment.dart';
import '../repositories/comment_repository.dart';

class AddComment {
  const AddComment(this._repository);

  final CommentRepository _repository;

  Future<Result<Comment>> call({
    required String articleId,
    String? parentId,
    required String authorName,
    required String content,
  }) =>
      _repository.addComment(
        articleId: articleId,
        parentId: parentId,
        authorName: authorName,
        content: content,
      );
}
