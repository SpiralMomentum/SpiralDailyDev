import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/widget_sync/data/home_widget_gateway.dart';

void main() {
  test('save stores every entry then updates the three providers', () async {
    final saved = <String, String>{};
    final updated = <String>[];
    final order = <String>[];
    final g = HomeWidgetGateway(
      saveData: (k, v) async {
        order.add('save');
        saved[k] = v;
      },
      updateWidget: (name) async {
        order.add('update');
        updated.add(name);
      },
    );

    await g.save({'total': '1,000원', 'ratio': '', 'asOf': '11/28 09:05'});

    expect(saved, {'total': '1,000원', 'ratio': '', 'asOf': '11/28 09:05'});
    expect(updated, [
      'com.spiralmomentum.spend_ledger.SmallSpendWidget',
      'com.spiralmomentum.spend_ledger.MediumSpendWidget',
      'com.spiralmomentum.spend_ledger.LargeSpendWidget',
    ]);
    expect(order.indexOf('update'), greaterThan(order.lastIndexOf('save')));
  });
}
