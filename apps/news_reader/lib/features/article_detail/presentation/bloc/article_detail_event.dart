import 'package:equatable/equatable.dart';

sealed class ArticleDetailEvent extends Equatable {
  const ArticleDetailEvent();
  @override
  List<Object?> get props => [];
}

class ArticleDetailStarted extends ArticleDetailEvent {
  const ArticleDetailStarted(this.articleId);
  final String articleId;
  @override
  List<Object?> get props => [articleId];
}

class ArticleDetailBookmarkToggled extends ArticleDetailEvent {
  const ArticleDetailBookmarkToggled();
}

class ArticleDetailRefreshed extends ArticleDetailEvent {
  const ArticleDetailRefreshed();
}
