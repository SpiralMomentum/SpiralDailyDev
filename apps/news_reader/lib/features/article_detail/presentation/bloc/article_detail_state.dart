import 'package:equatable/equatable.dart';

import 'package:apps.news_reader/features/news_feed/domain/entities/article.dart';

enum ArticleDetailStatus { initial, loading, loaded, error }

class ArticleDetailState extends Equatable {
  const ArticleDetailState({
    this.status = ArticleDetailStatus.initial,
    this.article,
    this.errorMessage,
  });

  final ArticleDetailStatus status;
  final Article? article;
  final String? errorMessage;

  ArticleDetailState copyWith({
    ArticleDetailStatus? status,
    Article? article,
    String? Function()? errorMessage,
  }) {
    return ArticleDetailState(
      status: status ?? this.status,
      article: article ?? this.article,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, article, errorMessage];
}
