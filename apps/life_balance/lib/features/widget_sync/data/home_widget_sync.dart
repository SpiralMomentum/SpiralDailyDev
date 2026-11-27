import 'package:home_widget/home_widget.dart';

import '../../balance/domain/balance_calculator.dart';
import '../../balance/domain/calendar_date.dart';
import '../../balance/domain/profile.dart';
import '../../life_table/domain/life_table.dart';
import '../../ongoing_notification/data/ongoing_notifier.dart';
import '../../ongoing_notification/domain/notification_text.dart';
import '../../profile/domain/settings.dart';
import '../../tone/domain/tone_table.dart';
import 'widget_payload.dart';

abstract interface class WidgetGateway {
  Future<void> save(Map<String, String> entries);
  Future<void> refresh();
}

class HomeWidgetGateway implements WidgetGateway {
  const HomeWidgetGateway();

  @override
  Future<void> save(Map<String, String> entries) async {
    for (final e in entries.entries) {
      await HomeWidget.saveWidgetData<String>(e.key, e.value);
    }
  }

  @override
  Future<void> refresh() async {
    await HomeWidget.updateWidget(
      qualifiedAndroidName: WidgetKeys.smallReceiver,
    );
    await HomeWidget.updateWidget(
      qualifiedAndroidName: WidgetKeys.mediumReceiver,
    );
  }
}

Future<void> syncWidget({
  required WidgetPayload payload,
  required WidgetGateway widgets,
}) async {
  await widgets.save(payload.toEntries());
  await widgets.refresh();
}

/// 프로필/설정에서 파생되는 출력(위젯, 상시 알림)을 오늘 기준으로 맞춘다.
Future<void> syncDerivedOutputs({
  required Profile profile,
  required AppSettings settings,
  required LifeTable table,
  required ToneTable tone,
  required CalendarDate today,
  required WidgetGateway widgets,
  required OngoingNotifier notifier,
}) async {
  await syncWidget(
    payload: buildWidgetPayload(
      profile: profile,
      settings: settings,
      table: table,
      tone: tone,
      today: today,
    ),
    widgets: widgets,
  );
  if (!settings.ongoingNotification) {
    await notifier.cancel();
    return;
  }
  final balance = computeBalance(
    birth: profile.birthDate,
    maturity: maturityDate(profile: profile, today: today, table: table),
    today: today,
  );
  await notifier.show(
    notificationText(
      balance: balance,
      unit: settings.unit,
      tone: tone,
      today: today,
    ),
  );
}
