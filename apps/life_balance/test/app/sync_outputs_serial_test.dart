import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/app/bootstrap.dart';
import 'package:life_balance/app/di/service_locator.dart';
import 'package:life_balance/app/life_balance_app.dart';
import 'package:life_balance/features/balance/domain/balance_format.dart';
import 'package:life_balance/features/balance/domain/calendar_date.dart';
import 'package:life_balance/features/balance/domain/profile.dart';
import 'package:life_balance/features/profile/domain/settings.dart';
import 'package:life_balance/features/widget_sync/data/home_widget_sync.dart';

import '../helpers/app_harness.dart';

/// 첫 save를 [gate]가 풀릴 때까지 붙잡아 두고 시작/끝 순서를 기록한다.
class _GatedGateway implements WidgetGateway {
  final log = <String>[];
  final gate = Completer<void>();
  bool throwFirst = false;
  var _n = 0;

  @override
  Future<void> save(Map<String, String> entries) async {
    final unit = entries['lb_unit'];
    log.add('start $unit');
    if (_n++ == 0) {
      await gate.future;
      if (throwFirst) throw StateError('boom');
    }
    log.add('end $unit');
  }

  @override
  Future<void> refresh() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const profile = Profile(
    birthDate: CalendarDate(1990, 1, 1),
    sex: Sex.male,
    countryCode: 'KR',
  );
  const days = AppSettings(unit: BalanceUnit.days);
  const weeks = AppSettings(unit: BalanceUnit.weeks);

  late _GatedGateway gateway;
  late AppAssets assets;

  setUp(() async {
    await Harness().setUp();
    gateway = _GatedGateway();
    sl
      ..unregister<WidgetGateway>()
      ..registerSingleton<WidgetGateway>(gateway);
    assets = (await loadAppAssets(sl()))!;
  });

  test('겹친 syncOutputs는 앞의 호출이 끝난 뒤 순서대로 실행된다', () async {
    final a = syncOutputs(profile, days, assets);
    final b = syncOutputs(profile, weeks, assets);
    await pumpEventQueue();
    expect(gateway.log, ['start days']);

    gateway.gate.complete();
    await Future.wait([a, b]);
    expect(gateway.log, ['start days', 'end days', 'start weeks', 'end weeks']);
  });

  test('앞의 호출이 실패해도 다음 호출은 실행된다', () async {
    gateway.throwFirst = true;
    final a = syncOutputs(profile, days, assets);
    final b = syncOutputs(profile, weeks, assets);
    gateway.gate.complete();
    await Future.wait([a, b]);
    expect(gateway.log, ['start days', 'start weeks', 'end weeks']);
  });
}
