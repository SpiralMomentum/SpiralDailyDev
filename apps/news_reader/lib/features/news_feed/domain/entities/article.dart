import 'package:equatable/equatable.dart';

enum ArticleCategory {
  technology,
  business,
  science,
  health,
  sports,
  entertainment,
  general,
  unknown,
}

class Article extends Equatable {
  const Article({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.imageUrl,
    required this.category,
    required this.isBookmarked,
    required this.commentCount,
    required this.publishedAt,
    required this.sourceName,
  });

  final String id;
  final String title;
  final String summary;
  final String content;
  final String imageUrl;
  final ArticleCategory category;
  final bool isBookmarked;
  final int commentCount;
  final DateTime publishedAt;
  final String sourceName;

  Article copyWith({
    String? id,
    String? title,
    String? summary,
    String? content,
    String? imageUrl,
    ArticleCategory? category,
    bool? isBookmarked,
    int? commentCount,
    DateTime? publishedAt,
    String? sourceName,
  }) {
    return Article(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      commentCount: commentCount ?? this.commentCount,
      publishedAt: publishedAt ?? this.publishedAt,
      sourceName: sourceName ?? this.sourceName,
    );
  }

  @override
  List<Object?> get props => [id, title, summary, content, imageUrl, category, isBookmarked, commentCount, publishedAt, sourceName];
}
