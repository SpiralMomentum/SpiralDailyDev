import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Surfaces where quotes should appear.
enum QuoteDisplayTarget { statusBar, lockScreen, homeWidget }

/// User configurable display preferences for quotes.
@immutable
class QuoteDisplayPreferences extends Equatable {
  /// Creates [QuoteDisplayPreferences].
  const QuoteDisplayPreferences({
    required this.enabledTargets,
    required this.refreshInterval,
  });

  /// Default preferences enabling all targets with a two-hour cadence.
  factory QuoteDisplayPreferences.defaults() {
    return const QuoteDisplayPreferences(
      enabledTargets: <QuoteDisplayTarget>{
        QuoteDisplayTarget.statusBar,
        QuoteDisplayTarget.lockScreen,
        QuoteDisplayTarget.homeWidget,
      },
      refreshInterval: Duration(hours: 2),
    );
  }

  /// Surfaces where quotes should appear.
  final Set<QuoteDisplayTarget> enabledTargets;

  /// How frequently to refresh content.
  final Duration refreshInterval;

  /// Returns true if the given [target] is active.
  bool isTargetEnabled(QuoteDisplayTarget target) =>
      enabledTargets.contains(target);

  /// Returns a copy with updated values.
  QuoteDisplayPreferences copyWith({
    Set<QuoteDisplayTarget>? enabledTargets,
    Duration? refreshInterval,
  }) {
    return QuoteDisplayPreferences(
      enabledTargets: enabledTargets ?? this.enabledTargets,
      refreshInterval: refreshInterval ?? this.refreshInterval,
    );
  }

  /// Serialises the preferences into a map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'enabledTargets': enabledTargets.map((t) => t.name).toList(),
      'refreshInterval': refreshInterval.inMinutes,
    };
  }

  /// Creates preferences from a map.
  factory QuoteDisplayPreferences.fromMap(Map<String, dynamic> map) {
    final List<dynamic> targets = map['enabledTargets'] as List<dynamic>? ??
        QuoteDisplayPreferences.defaults().enabledTargets.map((t) => t.name).toList();
    final Set<QuoteDisplayTarget> parsedTargets = targets
        .map((dynamic value) => QuoteDisplayTarget.values.firstWhere(
              (target) => target.name == value,
              orElse: () => QuoteDisplayTarget.statusBar,
            ))
        .toSet();

    final int minutes = (map['refreshInterval'] as num?)?.toInt() ?? 120;
    return QuoteDisplayPreferences(
      enabledTargets: parsedTargets,
      refreshInterval: Duration(minutes: minutes),
    );
  }

  @override
  List<Object?> get props => <Object?>[enabledTargets, refreshInterval];
}
