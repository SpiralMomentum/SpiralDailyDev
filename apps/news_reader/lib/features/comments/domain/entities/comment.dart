class Comment {
  const Comment({
    required this.id,
    required this.articleId,
    this.parentId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.isOptimistic = false,
  });

  final String id;
  final String articleId;
  final String? parentId;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final bool isOptimistic;

  Comment copyWith({
    String? id,
    String? articleId,
    String? Function()? parentId,
    String? authorName,
    String? content,
    DateTime? createdAt,
    bool? isOptimistic,
  }) {
    return Comment(
      id: id ?? this.id,
      articleId: articleId ?? this.articleId,
      parentId: parentId != null ? parentId() : this.parentId,
      authorName: authorName ?? this.authorName,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isOptimistic: isOptimistic ?? this.isOptimistic,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Comment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          articleId == other.articleId &&
          parentId == other.parentId &&
          authorName == other.authorName &&
          content == other.content &&
          createdAt == other.createdAt &&
          isOptimistic == other.isOptimistic;

  @override
  int get hashCode => Object.hash(
        id,
        articleId,
        parentId,
        authorName,
        content,
        createdAt,
        isOptimistic,
      );
}
