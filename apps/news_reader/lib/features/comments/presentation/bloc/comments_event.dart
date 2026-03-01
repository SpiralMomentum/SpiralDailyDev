import 'package:equatable/equatable.dart';

abstract class CommentsEvent extends Equatable {
  const CommentsEvent();

  @override
  List<Object?> get props => [];
}

class CommentsStarted extends CommentsEvent {
  const CommentsStarted(this.articleId);

  final String articleId;

  @override
  List<Object?> get props => [articleId];
}

class CommentAdded extends CommentsEvent {
  const CommentAdded({
    required this.articleId,
    this.parentId,
    required this.authorName,
    required this.content,
  });

  final String articleId;
  final String? parentId;
  final String authorName;
  final String content;

  @override
  List<Object?> get props => [articleId, parentId, authorName, content];
}

class CommentsRefreshed extends CommentsEvent {
  const CommentsRefreshed();
}
