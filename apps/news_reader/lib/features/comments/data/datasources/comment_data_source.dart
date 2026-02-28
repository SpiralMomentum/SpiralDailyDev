import '../dto/comment_dto.dart';

abstract class CommentDataSource {
  Stream<List<CommentDto>> watchComments(String articleId);

  Future<CommentDto> addComment({
    required String articleId,
    String? parentId,
    required String authorName,
    required String content,
  });
}
