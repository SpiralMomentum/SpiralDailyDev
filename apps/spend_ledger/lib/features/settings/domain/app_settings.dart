import 'package:equatable/equatable.dart';

import '../../ingest/domain/android_sources.dart';
import '../../message_filter/domain/filter_rule.dart';
import '../../message_filter/domain/name_registry.dart';

class AppSettings extends Equatable {
  const AppSettings({
    this.startDay = 1,
    this.budget,
    this.deleteRawText = true,
    this.hideAmounts = false,
    this.filters = defaultFilterRules,
    this.names = const NameRegistry.empty(),
    this.notificationPackages = defaultNotificationPackages,
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
  );

  final int startDay;
  final int? budget;
  final bool deleteRawText;
  final bool hideAmounts;
  final List<FilterRule> filters;
  final NameRegistry names;

  /// Android에서 알림을 수집할 앱 패키지.
  final List<String> notificationPackages;

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
  }) => AppSettings(
    startDay: startDay ?? this.startDay,
    budget: clearBudget ? null : (budget ?? this.budget),
    deleteRawText: deleteRawText ?? this.deleteRawText,
    hideAmounts: hideAmounts ?? this.hideAmounts,
    filters: filters ?? this.filters,
    names: names ?? this.names,
    notificationPackages: notificationPackages ?? this.notificationPackages,
  );

  Map<String, dynamic> toJson() => {
    'startDay': startDay,
    'budget': budget,
    'deleteRawText': deleteRawText,
    'hideAmounts': hideAmounts,
    'filters': [for (final f in filters) f.toJson()],
    'names': names.toJson(),
    'notificationPackages': notificationPackages,
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
  ];
}
