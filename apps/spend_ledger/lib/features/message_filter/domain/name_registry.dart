import 'package:equatable/equatable.dart';

class NameRegistry extends Equatable {
  const NameRegistry({
    required this.selfNames,
    required this.chargeTargets,
    required this.prepaidMoneys,
  });

  const NameRegistry.empty()
      : selfNames = const [],
        chargeTargets = const [],
        prepaidMoneys = const [];

  factory NameRegistry.fromJson(Map<String, dynamic> json) => NameRegistry(
        selfNames: List<String>.from(json['selfNames'] as List? ?? const []),
        chargeTargets:
            List<String>.from(json['chargeTargets'] as List? ?? const []),
        prepaidMoneys:
            List<String>.from(json['prepaidMoneys'] as List? ?? const []),
      );

  final List<String> selfNames;
  final List<String> chargeTargets;
  final List<String> prepaidMoneys;

  Map<String, dynamic> toJson() => {
        'selfNames': selfNames,
        'chargeTargets': chargeTargets,
        'prepaidMoneys': prepaidMoneys,
      };

  @override
  List<Object?> get props => [selfNames, chargeTargets, prepaidMoneys];
}
