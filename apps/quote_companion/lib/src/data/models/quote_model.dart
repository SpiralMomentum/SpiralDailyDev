import '../../domain/entities/quote.dart';

/// Data transfer model for [Quote].
class QuoteModel extends Quote {
  /// Creates a [QuoteModel].
  const QuoteModel({
    required super.id,
    required super.text,
    required super.author,
    required super.source,
    required super.createdAt,
  });

  /// Builds a model from a [Quote].
  factory QuoteModel.fromEntity(Quote quote) {
    return QuoteModel(
      id: quote.id,
      text: quote.text,
      author: quote.author,
      source: quote.source,
      createdAt: quote.createdAt,
    );
  }

  /// Builds a model from a json map.
  factory QuoteModel.fromJson(Map<String, dynamic> json) {
    return QuoteModel(
      id: json['id'] as String,
      text: json['text'] as String,
      author: json['author'] as String? ?? '',
      source: QuoteSourceType.values.firstWhere(
        (value) => value.name == json['source'],
        orElse: () => QuoteSourceType.curated,
      ),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Converts to json.
  Map<String, dynamic> toJson() => toMap();
}
