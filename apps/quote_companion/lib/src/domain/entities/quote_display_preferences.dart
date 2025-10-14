import 'package:equatable/equatable.dart';

/// User preferences for where quotes should be shown.
class QuoteDisplayPreferences extends Equatable {
  /// Creates [QuoteDisplayPreferences].
  const QuoteDisplayPreferences({
    required this.statusBarEnabled,
    required this.lockScreenEnabled,
    required this.homeWidgetEnabled,
  });

  /// Default configuration enabling every surface.
  const QuoteDisplayPreferences.defaults()
      : this(
          statusBarEnabled: true,
          lockScreenEnabled: true,
          homeWidgetEnabled: true,
        );

  /// Whether the status bar surface is enabled.
  final bool statusBarEnabled;

  /// Whether the lock screen surface is enabled.
  final bool lockScreenEnabled;

  /// Whether the home widget surface is enabled.
  final bool homeWidgetEnabled;

  /// Creates a copy with updated values.
  QuoteDisplayPreferences copyWith({
    bool? statusBarEnabled,
    bool? lockScreenEnabled,
    bool? homeWidgetEnabled,
  }) {
    return QuoteDisplayPreferences(
      statusBarEnabled: statusBarEnabled ?? this.statusBarEnabled,
      lockScreenEnabled: lockScreenEnabled ?? this.lockScreenEnabled,
      homeWidgetEnabled: homeWidgetEnabled ?? this.homeWidgetEnabled,
    );
  }

  /// Serialises the preferences to a map for persistence.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'statusBarEnabled': statusBarEnabled,
        'lockScreenEnabled': lockScreenEnabled,
        'homeWidgetEnabled': homeWidgetEnabled,
      };

  @override
  List<Object?> get props => <Object?>[
        statusBarEnabled,
        lockScreenEnabled,
        homeWidgetEnabled,
      ];
}
