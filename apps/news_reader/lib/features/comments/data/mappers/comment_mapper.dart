import '../../domain/entities/comment.dart';
import '../dto/comment_dto.dart';

class CommentMapper {
  const CommentMapper._();

  static Comment toDomain(CommentDto dto) {
    return Comment(
      id: dto.id,
      articleId: dto.article_id,
      parentId: dto.parent_id,
      authorName: dto.author_name,
      content: dto.content,
      createdAt: DateTime.tryParse(dto.created_at ?? '') ?? DateTime.now(),
    );
  }

  static CommentDto toDto(Comment comment) {
    return CommentDto(
      id: comment.id,
      article_id: comment.articleId,
      parent_id: comment.parentId,
      author_name: comment.authorName,
      content: comment.content,
      created_at: comment.createdAt.toIso8601String(),
    );
  }
}
