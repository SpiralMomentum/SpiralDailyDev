import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/life_table/data/asset_life_table_repository.dart';
import '../features/profile/domain/profile_repository.dart';
import '../features/tone/data/asset_tone_repository.dart';
import '../features/tone/domain/tone.dart';
import '../features/tone/domain/tone_table.dart';
import 'app_config.dart';
import 'di/service_locator.dart';
import 'font_licenses.dart';
import 'life_balance_app.dart';

/// 플랫폼 의존성을 등록한 뒤 첫 화면 위젯을 만든다.
Future<Widget> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  final prefs = await SharedPreferences.getInstance();
  await ServiceLocator.setup(config: config, prefs: prefs);
  return startApp();
}

/// 생명표와 세 말투를 모두 읽는다. 하나라도 실패하면 null.
Future<AppAssets?> loadAppAssets(AssetBundle bundle) async {
  final table = (await AssetLifeTableRepository(
    bundle: bundle,
  ).load()).dataOrNull;
  if (table == null) return null;
  final toneRepo = AssetToneRepository(bundle: bundle);
  final tones = <ToneId, ToneTable>{};
  for (final id in ToneId.values) {
    final tone = (await toneRepo.load(id)).dataOrNull;
    if (tone == null) return null;
    tones[id] = tone;
  }
  return AppAssets(table: table, tones: Map.unmodifiable(tones));
}

/// get_it에 등록된 의존성으로 데이터를 읽고 첫 화면을 고른다.
/// 프로필이 있으면 위젯/알림을 맞추고 갱신 작업을 예약한 뒤 통장 화면,
/// 없으면 온보딩. 데이터 로드에 실패하면 오류 화면.
Future<Widget> startApp() async {
  try {
    await sl<BackgroundInitializer>().initialize();
  } catch (e) {
    debugPrint('background initialize failed: $e');
  }
  final assets = await loadAppAssets(sl<AssetBundle>());
  if (assets == null) return const LoadErrorApp();

  final repo = sl<ProfileRepository>();
  final profile = await repo.loadProfile();
  final settings = await repo.loadSettings();
  if (profile != null) {
    await syncOutputs(profile, settings, assets);
    await ensureRefreshScheduled();
  }
  return LifeBalanceApp(
    assets: assets,
    initialProfile: profile,
    initialSettings: settings,
  );
}
