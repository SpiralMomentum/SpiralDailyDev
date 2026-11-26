import 'package:equatable/equatable.dart';

import '../../balance/domain/balance_format.dart';
import '../../tone/domain/tone.dart';

enum ThemePref { system, light, dark }

class AppSettings extends Equatable {
  const AppSettings({
    this.unit = BalanceUnit.days,
    this.tone = ToneId.stoic,
    this.themePref = ThemePref.system,
    this.ongoingNotification = true,
  });

  static const defaults = AppSettings();

  final BalanceUnit unit;
  final ToneId tone;
  final ThemePref themePref;
  final bool ongoingNotification;

  AppSettings copyWith({
    BalanceUnit? unit,
    ToneId? tone,
    ThemePref? themePref,
    bool? ongoingNotification,
  }) => AppSettings(
    unit: unit ?? this.unit,
    tone: tone ?? this.tone,
    themePref: themePref ?? this.themePref,
    ongoingNotification: ongoingNotification ?? this.ongoingNotification,
  );

  @override
  List<Object?> get props => [unit, tone, themePref, ongoingNotification];
}
