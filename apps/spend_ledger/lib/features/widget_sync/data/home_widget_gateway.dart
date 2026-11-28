import 'package:home_widget/home_widget.dart';

import '../../ingest/domain/ingest.dart';

const _package = 'com.spiralmomentum.spend_ledger';
const _providers = [
  '$_package.SmallSpendWidget',
  '$_package.MediumSpendWidget',
  '$_package.LargeSpendWidget',
];

Future<void> _defaultSave(String key, String value) async {
  await HomeWidget.saveWidgetData<String>(key, value);
}

Future<void> _defaultUpdate(String qualifiedName) async {
  await HomeWidget.updateWidget(qualifiedAndroidName: qualifiedName);
}

/// 위젯 페이로드를 home_widget 저장소에 쓰고 세 위젯을 다시 그리게 한다.
class HomeWidgetGateway implements WidgetGateway {
  HomeWidgetGateway({
    Future<void> Function(String key, String value) saveData = _defaultSave,
    Future<void> Function(String qualifiedName) updateWidget = _defaultUpdate,
  }) : _save = saveData,
       _update = updateWidget;

  final Future<void> Function(String key, String value) _save;
  final Future<void> Function(String qualifiedName) _update;

  @override
  Future<void> save(Map<String, String> entries) async {
    for (final e in entries.entries) {
      await _save(e.key, e.value);
    }
    for (final name in _providers) {
      await _update(name);
    }
  }
}
