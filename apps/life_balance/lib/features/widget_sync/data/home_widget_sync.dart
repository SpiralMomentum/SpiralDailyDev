import 'package:home_widget/home_widget.dart';

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
