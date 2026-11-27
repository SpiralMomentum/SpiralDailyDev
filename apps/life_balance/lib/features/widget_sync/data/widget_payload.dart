import 'dart:convert';
import 'dart:ui' show Brightness;

import 'package:equatable/equatable.dart';

import '../../balance/domain/calendar_date.dart';
import '../../balance/domain/maturity_schedule.dart';
import '../../balance/domain/profile.dart';
import '../../life_table/domain/life_table.dart';
import '../../profile/domain/settings.dart';
import '../../tone/domain/phrase_keys.dart';
import '../../tone/domain/tone_table.dart';
import '../../tone/presentation/tone_theme.dart';

/// 위젯 저장소 키. Kotlin 위젯(Task 10)과 공유하는 계약이므로 이름을 바꾸지 않는다.
abstract final class WidgetKeys {
  static const schedule = 'lb_schedule';
  static const birth = 'lb_birth';
  static const unit = 'lb_unit';
  static const tone = 'lb_tone';
  static const colorsLight = 'lb_colors_light';
  static const colorsDark = 'lb_colors_dark';
  static const phrases = 'lb_phrases';

  /// 상시 알림 설정. "1"이면 켜짐, "0"이면 꺼짐. 재부팅 후 Kotlin이 알림을 다시 띄울지 판단한다.
  static const notify = 'lb_notify';

  static const all = [
    schedule,
    birth,
    unit,
    tone,
    colorsLight,
    colorsDark,
    phrases,
    notify,
  ];

  static const smallReceiver =
      'com.spiralmomentum.life_balance.widget.SmallBalanceReceiver';
  static const mediumReceiver =
      'com.spiralmomentum.life_balance.widget.MediumBalanceReceiver';

  static const phraseKeys = [
    PhraseKeys.widgetSmallLabel,
    PhraseKeys.widgetMediumLabel,
    PhraseKeys.widgetWithdrawal,
    PhraseKeys.widgetBonusLabel,
    PhraseKeys.notificationBody,
    PhraseKeys.notificationBonusBody,
  ];
}

class WidgetPayload extends Equatable {
  const WidgetPayload({
    required this.entries,
  });

  final Map<String, String> entries;

  Map<String, String> toEntries() => entries;

  @override
  List<Object?> get props => [entries];
}

String _colorsJson(TonePalette p) => jsonEncode({
      'bg': p.background.toARGB32(),
      'fg': p.foreground.toARGB32(),
      'accent': p.accent.toARGB32(),
    });

WidgetPayload buildWidgetPayload({
  required Profile profile,
  required AppSettings settings,
  required LifeTable table,
  required ToneTable tone,
  required CalendarDate today,
}) {
  final schedule = buildSchedule(profile: profile, today: today, table: table);
  return WidgetPayload(
    entries: Map.unmodifiable({
      WidgetKeys.schedule: jsonEncode([for (final e in schedule) e.toJson()]),
      WidgetKeys.birth: profile.birthDate.toIso(),
      WidgetKeys.unit: settings.unit.name,
      WidgetKeys.tone: settings.tone.name,
      WidgetKeys.colorsLight:
          _colorsJson(paletteFor(settings.tone, Brightness.light)),
      WidgetKeys.colorsDark:
          _colorsJson(paletteFor(settings.tone, Brightness.dark)),
      WidgetKeys.phrases: jsonEncode({
        for (final k in WidgetKeys.phraseKeys) k: tone.phrases[k] ?? [k],
      }),
      WidgetKeys.notify: settings.ongoingNotification ? '1' : '0',
    }),
  );
}
