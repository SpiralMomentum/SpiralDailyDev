import 'package:equatable/equatable.dart';

enum SyncStatus {
  synced,
  pendingUpload,
  pendingDelete,
  conflict,
}

class Bookmark extends Equatable {
  const Bookmark({
    required this.articleId,
    required this.title,
    required this.summary,
    required this.content,
    required this.imageUrl,
    required this.category,
    required this.savedAt,
    required this.syncStatus,
    this.highlightedText,
  });

  final String articleId;
  final String title;
  final String summary;
  final String content;
  final String imageUrl;
  final String category;
  final DateTime savedAt;
  final SyncStatus syncStatus;
  final String? highlightedText;

  Bookmark copyWith({
    String? articleId,
    String? title,
    String? summary,
    String? content,
    String? imageUrl,
    String? category,
    DateTime? savedAt,
    SyncStatus? syncStatus,
    String? highlightedText,
  }) {
    return Bookmark(
      articleId: articleId ?? this.articleId,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      savedAt: savedAt ?? this.savedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      highlightedText: highlightedText ?? this.highlightedText,
    );
  }

  @override
  List<Object?> get props => [articleId, title, summary, content, imageUrl, category, savedAt, syncStatus, highlightedText];
}
