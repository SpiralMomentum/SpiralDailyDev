import '../../domain/entities/feedback_entry.dart';

/// Model representation for [FeedbackEntry].
class FeedbackEntryModel extends FeedbackEntry {
  /// Creates a [FeedbackEntryModel].
  const FeedbackEntryModel({
    required super.id,
    required super.message,
    required super.rating,
    required super.createdAt,
    super.contactEmail,
  });

  /// Creates a model from domain entity.
  factory FeedbackEntryModel.fromEntity(FeedbackEntry entry) {
    return FeedbackEntryModel(
      id: entry.id,
      message: entry.message,
      rating: entry.rating,
      createdAt: entry.createdAt,
      contactEmail: entry.contactEmail,
    );
  }

  /// Creates a model from JSON map.
  factory FeedbackEntryModel.fromJson(Map<String, dynamic> json) {
    return FeedbackEntryModel(
      id: json['id'] as String,
      message: json['message'] as String,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      contactEmail: json['contactEmail'] as String?,
    );
  }

  /// Serialises to JSON.
  Map<String, dynamic> toJson() => toMap();
}
