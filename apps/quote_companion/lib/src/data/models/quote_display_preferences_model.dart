import '../../domain/entities/quote_display_preferences.dart';

/// Model representation of [QuoteDisplayPreferences].
class QuoteDisplayPreferencesModel extends QuoteDisplayPreferences {
  /// Creates a [QuoteDisplayPreferencesModel].
  const QuoteDisplayPreferencesModel({
    required super.enabledTargets,
    required super.refreshInterval,
  });

  /// Builds a model from domain entity.
  factory QuoteDisplayPreferencesModel.fromEntity(
    QuoteDisplayPreferences preferences,
  ) {
    return QuoteDisplayPreferencesModel(
      enabledTargets: preferences.enabledTargets,
      refreshInterval: preferences.refreshInterval,
    );
  }

  /// Builds a model from JSON.
  factory QuoteDisplayPreferencesModel.fromJson(Map<String, dynamic> json) {
    return QuoteDisplayPreferencesModel(
      enabledTargets: QuoteDisplayPreferences.fromMap(json).enabledTargets,
      refreshInterval: QuoteDisplayPreferences.fromMap(json).refreshInterval,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => toMap();
}
