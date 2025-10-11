import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Represents the source of a quote.
enum QuoteSourceType {
  /// Curated by the content team and bundled in the application assets.
  curated,

  /// Added by the end user.
  custom,

  /// Downloaded from community or remote sources.
  community,
}

/// Entity describing a quote displayed to the user.
@immutable
class Quote extends Equatable {
  /// Creates a [Quote].
  const Quote({
    required this.id,
    required this.text,
    required this.author,
    required this.source,
    required this.createdAt,
  });

  /// Unique identifier.
  final String id;

  /// Body text of the quote.
  final String text;

  /// Optional author attribution.
  final String author;

  /// Where the quote originated from.
  final QuoteSourceType source;

  /// Timestamp when the quote was created or ingested.
  final DateTime createdAt;

  /// Convenience factory for creating curated quotes with deterministic ids.
  factory Quote.curated({
    required String id,
    required String text,
    required String author,
  }) {
    return Quote(
      id: id,
      text: text,
      author: author,
      source: QuoteSourceType.curated,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// Creates a copy of the quote with updates.
  Quote copyWith({
    String? id,
    String? text,
    String? author,
    QuoteSourceType? source,
    DateTime? createdAt,
  }) {
    return Quote(
      id: id ?? this.id,
      text: text ?? this.text,
      author: author ?? this.author,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Serialises the quote to a map for storage.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'text': text,
      'author': author,
      'source': source.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates a [Quote] from a map.
  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id'] as String,
      text: map['text'] as String,
      author: map['author'] as String? ?? '',
      source: QuoteSourceType.values.firstWhere(
        (type) => type.name == map['source'],
        orElse: () => QuoteSourceType.curated,
      ),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  @override
  List<Object?> get props => <Object?>[id, text, author, source, createdAt];
}
