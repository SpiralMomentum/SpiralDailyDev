class ArticleDto {
  const ArticleDto({
    required this.id,
    required this.title,
    this.summary,
    this.content,
    this.imageUrl,
    this.category,
    this.commentCount,
    this.publishedAt,
    this.sourceName,
  });

  final String id;
  final String title;
  final String? summary;
  final String? content;
  final String? imageUrl;
  final String? category;
  final int? commentCount;
  final String? publishedAt;
  final String? sourceName;

  factory ArticleDto.fromJson(Map<String, dynamic> json) {
    return ArticleDto(
      id: json['id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String?,
      content: json['content'] as String?,
      imageUrl: json['image_url'] as String?,
      category: json['category'] as String?,
      commentCount: json['comment_count'] as int?,
      publishedAt: json['published_at'] as String?,
      sourceName: json['source_name'] as String?,
    );
  }
}
