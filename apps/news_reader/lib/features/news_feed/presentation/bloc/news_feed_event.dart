import 'package:equatable/equatable.dart';
import 'package:apps.news_reader/features/news_feed/domain/entities/article.dart';

sealed class NewsFeedEvent extends Equatable {
  const NewsFeedEvent();
  @override
  List<Object?> get props => [];
}

class NewsFeedStarted extends NewsFeedEvent {
  const NewsFeedStarted();
}

class NewsFeedRefreshed extends NewsFeedEvent {
  const NewsFeedRefreshed();
}

class NewsFeedNextPageRequested extends NewsFeedEvent {
  const NewsFeedNextPageRequested();
}

class NewsFeedCategoryChanged extends NewsFeedEvent {
  const NewsFeedCategoryChanged(this.category);
  final ArticleCategory? category;
  @override
  List<Object?> get props => [category];
}

class NewsFeedBookmarkToggled extends NewsFeedEvent {
  const NewsFeedBookmarkToggled(this.article);
  final Article article;
  @override
  List<Object?> get props => [article];
}
