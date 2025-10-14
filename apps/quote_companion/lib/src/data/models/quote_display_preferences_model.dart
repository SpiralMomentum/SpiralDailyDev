import '../../domain/entities/quote_display_preferences.dart';

/// Data model for persisting [QuoteDisplayPreferences].
class QuoteDisplayPreferencesModel extends QuoteDisplayPreferences {
  /// Creates [QuoteDisplayPreferencesModel].
  const QuoteDisplayPreferencesModel({
    required super.statusBarEnabled,
    required super.lockScreenEnabled,
    required super.homeWidgetEnabled,
  });

  /// Default configuration mirroring the domain defaults.
  const QuoteDisplayPreferencesModel.defaults()
      : super.defaults();

  /// Builds a model from the domain entity.
  factory QuoteDisplayPreferencesModel.fromEntity(
    QuoteDisplayPreferences preferences,
  ) {
    return QuoteDisplayPreferencesModel(
      statusBarEnabled: preferences.statusBarEnabled,
      lockScreenEnabled: preferences.lockScreenEnabled,
      homeWidgetEnabled: preferences.homeWidgetEnabled,
    );
  }

  /// Builds a model from a JSON payload.
  factory QuoteDisplayPreferencesModel.fromJson(Map<String, dynamic> json) {
    return QuoteDisplayPreferencesModel(
      statusBarEnabled: (json['statusBarEnabled'] as bool?) ?? true,
      lockScreenEnabled: (json['lockScreenEnabled'] as bool?) ?? true,
      homeWidgetEnabled: (json['homeWidgetEnabled'] as bool?) ?? true,
    );
  }

  /// Serialises the model to JSON.
  Map<String, dynamic> toJson() => toMap();
}
