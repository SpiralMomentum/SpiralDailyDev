import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Represents a user feedback submission captured via the VOC process.
@immutable
class FeedbackEntry extends Equatable {
  /// Creates a [FeedbackEntry].
  const FeedbackEntry({
    required this.id,
    required this.message,
    required this.rating,
    required this.createdAt,
    this.contactEmail,
  });

  /// Unique identifier.
  final String id;

  /// Free-form feedback message.
  final String message;

  /// Optional satisfaction rating between 1 and 5.
  final int rating;

  /// Optional contact email to follow up with the user.
  final String? contactEmail;

  /// Timestamp of submission.
  final DateTime createdAt;

  /// Serialises to a map for persistence.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'message': message,
      'rating': rating,
      'contactEmail': contactEmail,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates an entry from a map.
  factory FeedbackEntry.fromMap(Map<String, dynamic> map) {
    return FeedbackEntry(
      id: map['id'] as String,
      message: map['message'] as String,
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      contactEmail: map['contactEmail'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  @override
  List<Object?> get props => <Object?>[id, message, rating, contactEmail, createdAt];
}
