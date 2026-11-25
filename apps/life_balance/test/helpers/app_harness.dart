import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:life_balance/app/app_config.dart';
import 'package:life_balance/app/di/service_locator.dart';
import 'package:life_balance/features/balance/domain/profile.dart';
import 'package:life_balance/features/ongoing_notification/data/midnight_scheduler.dart';
import 'package:life_balance/features/ongoing_notification/data/ongoing_notifier.dart';
import 'package:life_balance/features/profile/data/prefs_profile_repository.dart';
import 'package:life_balance/features/profile/domain/settings.dart';
import 'package:life_balance/features/profile/presentation/onboarding/widget_pinner.dart';
import 'package:life_balance/features/widget_sync/data/home_widget_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeGateway implements WidgetGateway {
  final saves = <Map<String, String>>[];
  int refreshes = 0;

  @override
  Future<void> save(Map<String, String> entries) async => saves.add(entries);

  @override
  Future<void> refresh() async => refreshes++;
}

class FakeNotifier implements OngoingNotifier {
  FakeNotifier({this.granted = true});
  final bool granted;
  final shown = <String>[];
  int cancels = 0;

  @override
  Future<bool> requestPermission() async => granted;

  @override
  Future<void> show(String text) async => shown.add(text);

  @override
  Future<void> cancel() async => cancels++;
}

class FakeScheduler implements RefreshScheduler {
  final calls = <DateTime>[];
  final fromMidnightJob = <bool>[];

  @override
  Future<void> ensureScheduled(
    DateTime now, {
    bool fromMidnightJob = false,
  }) async {
    calls.add(now);
    this.fromMidnightJob.add(fromMidnightJob);
  }
}

class FakeBackground implements BackgroundInitializer {
  int calls = 0;

  @override
  Future<void> initialize() async => calls++;
}

class FakePinner implements WidgetPinner {
  @override
  Future<bool> isSupported() async => false;

  @override
  Future<void> requestPin() async {}
}

List<double> _series(double e0) => [
  for (var a = 0; a <= 100; a++) (e0 - a).clamp(2.0, 200.0).toDouble(),
];

Map<String, dynamic> _country(String name, double m, double f) => {
  'name': name,
  'source': {
    'name': 'WHO GHO',
    'url': 'https://example.invalid',
    'year': 2023,
    'retrieved': '2026-11-01',
  },
  'male': _series(m),
  'female': _series(f),
};

/// 시험용 작은 생명표. KR 남성 e(a) = 80 - a.
final testLifeTableJson = jsonEncode({
  'version': 'test',
  'countries': {'KR': _country('대한민국', 80, 86), 'JP': _country('일본', 81, 87)},
});

/// 실제 말투 파일은 디스크에서 읽고, 생명표는 [lifeTable]을 돌려준다.
/// null이면 해당 에셋이 없는 것처럼 실패한다.
class TestBundle extends CachingAssetBundle {
  TestBundle({String? lifeTable, this.tonesAvailable = true})
    : _lifeTable = lifeTable;

  final String? _lifeTable;
  final bool tonesAvailable;

  @override
  Future<ByteData> load(String key) async {
    final bytes = utf8.encode(await loadString(key));
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == 'assets/life_tables/life_tables.json') {
      final t = _lifeTable;
      if (t == null) throw FlutterError('not found: $key');
      return t;
    }
    if (key.startsWith('assets/tones/')) {
      if (!tonesAvailable) throw FlutterError('not found: $key');
      return File(key).readAsStringSync();
    }
    throw FlutterError('not found: $key');
  }
}

class Harness {
  final gateway = FakeGateway();
  final notifier = FakeNotifier();
  final scheduler = FakeScheduler();
  final background = FakeBackground();
  final opened = <Uri>[];
  DateTime now = DateTime(2026, 11, 25, 9);
  late SharedPreferences prefs;

  /// 저장소를 준비하고 get_it에 fake를 등록한다.
  Future<void> setUp({
    Profile? profile,
    AppSettings? settings,
    String? lifeTable,
    bool lifeTableAvailable = true,
    bool tonesAvailable = true,
    AppConfig config = const AppConfig(),
  }) async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    final repo = PrefsProfileRepository(prefs);
    if (profile != null) await repo.saveProfile(profile);
    if (settings != null) await repo.saveSettings(settings);
    await ServiceLocator.setup(
      config: config,
      prefs: prefs,
      bundle: TestBundle(
        lifeTable: lifeTableAvailable ? (lifeTable ?? testLifeTableJson) : null,
        tonesAvailable: tonesAvailable,
      ),
      widgets: gateway,
      notifier: notifier,
      scheduler: scheduler,
      background: background,
      pinner: FakePinner(),
      opener: (uri) async => opened.add(uri),
      now: () => now,
      deviceCountry: () => 'KR',
    );
  }
}
