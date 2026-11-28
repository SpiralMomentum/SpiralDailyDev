import 'package:equatable/equatable.dart';

import '../../ingest/domain/android_sources.dart';
import '../../message_filter/domain/filter_rule.dart';
import '../../message_filter/domain/name_registry.dart';
import '../../theme/domain/palette.dart';

class AppSettings extends Equatable {
  const AppSettings({
    this.startDay = 1,
    this.budget,
    this.deleteRawText = true,
    this.hideAmounts = false,
    this.filters = defaultFilterRules,
    this.names = const NameRegistry.empty(),
    this.notificationPackages = defaultNotificationPackages,
    this.themeId = AppThemeId.navy,
    this.themeMode = AppThemeMode.system,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    startDay: json['startDay'] as int? ?? 1,
    budget: json['budget'] as int?,
    deleteRawText: json['deleteRawText'] as bool? ?? true,
    hideAmounts: json['hideAmounts'] as bool? ?? false,
    filters: json['filters'] == null
        ? defaultFilterRules
        : [
            for (final f in json['filters'] as List)
              FilterRule.fromJson(f as Map<String, dynamic>),
          ],
    names: json['names'] == null
        ? const NameRegistry.empty()
        : NameRegistry.fromJson(json['names'] as Map<String, dynamic>),
    notificationPackages: json['notificationPackages'] == null
        ? defaultNotificationPackages
        : [for (final p in json['notificationPackages'] as List) p as String],
    themeId: AppThemeId.fromName(_str(json['themeId'])),
    themeMode: AppThemeMode.fromName(_str(json['themeMode'])),
  );

  static String? _str(Object? v) => v is String ? v : null;

  final int startDay;
  final int? budget;
  final bool deleteRawText;
  final bool hideAmounts;
  final List<FilterRule> filters;
  final NameRegistry names;

  /// Android에서 알림을 수집할 앱 패키지.
  final List<String> notificationPackages;
  final AppThemeId themeId;
  final AppThemeMode themeMode;

  /// 예산을 지우려면 [clearBudget]을 true로 지정한다.
  AppSettings copyWith({
    int? startDay,
    int? budget,
    bool clearBudget = false,
    bool? deleteRawText,
    bool? hideAmounts,
    List<FilterRule>? filters,
    NameRegistry? names,
    List<String>? notificationPackages,
    AppThemeId? themeId,
    AppThemeMode? themeMode,
  }) => AppSettings(
    startDay: startDay ?? this.startDay,
    budget: clearBudget ? null : (budget ?? this.budget),
    deleteRawText: deleteRawText ?? this.deleteRawText,
    hideAmounts: hideAmounts ?? this.hideAmounts,
    filters: filters ?? this.filters,
    names: names ?? this.names,
    notificationPackages: notificationPackages ?? this.notificationPackages,
    themeId: themeId ?? this.themeId,
    themeMode: themeMode ?? this.themeMode,
  );

  Map<String, dynamic> toJson() => {
    'startDay': startDay,
    'budget': budget,
    'deleteRawText': deleteRawText,
    'hideAmounts': hideAmounts,
    'filters': [for (final f in filters) f.toJson()],
    'names': names.toJson(),
    'notificationPackages': notificationPackages,
    'themeId': themeId.name,
    'themeMode': themeMode.name,
  };

  @override
  List<Object?> get props => [
    startDay,
    budget,
    deleteRawText,
    hideAmounts,
    filters,
    names,
    notificationPackages,
    themeId,
    themeMode,
  ];
}
