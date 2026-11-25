import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/features/widget_sync/data/home_widget_sync.dart';
import 'package:life_balance/features/widget_sync/data/widget_payload.dart';
import 'package:mocktail/mocktail.dart';

class _MockGateway extends Mock implements WidgetGateway {}

void main() {
  test('syncWidget saves then refreshes', () async {
    final gw = _MockGateway();
    when(() => gw.save(any())).thenAnswer((_) async {});
    when(() => gw.refresh()).thenAnswer((_) async {});
    const payload = WidgetPayload(entries: {'lb_birth': '1990-05-01'});

    await syncWidget(payload: payload, widgets: gw);

    verifyInOrder([
      () => gw.save({'lb_birth': '1990-05-01'}),
      () => gw.refresh(),
    ]);
    verifyNoMoreInteractions(gw);
  });
}
