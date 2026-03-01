// ignore_for_file: non_constant_identifier_names

class CommentDto {
  const CommentDto({
    required this.id,
    required this.article_id,
    this.parent_id,
    required this.author_name,
    required this.content,
    this.created_at,
  });

  final String id;
  final String article_id;
  final String? parent_id;
  final String author_name;
  final String content;
  final String? created_at;

  factory CommentDto.fromJson(Map<String, dynamic> json) {
    return CommentDto(
      id: json['id'] as String,
      article_id: json['article_id'] as String,
      parent_id: json['parent_id'] as String?,
      author_name: json['author_name'] as String,
      content: json['content'] as String,
      created_at: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'article_id': article_id,
      'parent_id': parent_id,
      'author_name': author_name,
      'content': content,
      'created_at': created_at,
    };
  }
}
