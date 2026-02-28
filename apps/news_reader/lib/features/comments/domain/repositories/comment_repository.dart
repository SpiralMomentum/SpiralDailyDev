import 'package:utils/result/result.dart';

import '../entities/comment.dart';

abstract class CommentRepository {
  Stream<List<Comment>> watchComments(String articleId);

  Future<Result<Comment>> addComment({
    required String articleId,
    String? parentId,
    required String authorName,
    required String content,
  });
}
