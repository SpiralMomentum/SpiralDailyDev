import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../ingest/data/android_bridge.dart';
import '../../message_filter/domain/filter_rule.dart';
import '../../message_filter/domain/name_registry.dart';
import '../../theme/domain/palette.dart';
import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

final class SettingsState extends Equatable {
  const SettingsState({
    this.settings = const AppSettings(),
    this.loading = true,
    this.loaded = false,
    this.error,
  });

  final AppSettings settings;
  final bool loading;

  /// 저장소에서 설정을 한 번이라도 읽었는지. false면 [settings]는 실제 값이 아닌 기본값이다.
  final bool loaded;

  /// 마지막 읽기·저장이 실패했을 때 보여 줄 문구. 설정값은 이전 값을 유지한다.
  final String? error;

  @override
  List<Object?> get props => [settings, loading, loaded, error];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(
    this._repo,
    this._refresh, {
    AndroidBridge bridge = const AndroidBridge(),
    AppSettings? initial,
  }) : _bridge = bridge,
       super(
         initial == null
             ? const SettingsState()
             : SettingsState(settings: initial, loading: false, loaded: true),
       );

  final SettingsRepository _repo;
  final AndroidBridge _bridge;
  final Future<void> Function() _refresh;

  /// 저장소에서 설정을 한 번이라도 읽었는지. 읽기 전에는 기본값을 저장하지 않는다.
  bool get _loaded => state.loaded;

  /// 설정을 아직 읽지 못했을 때만 다시 읽는다. 화면을 열 때 재시도하는 데 쓴다.
  Future<void> loadIfNeeded() => _loaded ? Future<void>.value() : load();

  /// 아직 읽지 못한 상태면 읽는 동안 [SettingsState.loading]을 켠다.
  /// 그래서 다시 시도가 또 실패해도 상태가 바뀌어 화면이 오류를 다시 알린다.
  Future<void> load() async {
    if (!_loaded && !state.loading) {
      emit(SettingsState(settings: state.settings));
    }
    try {
      final loaded = await _repo.load();
      if (isClosed) return;
      emit(SettingsState(settings: loaded, loading: false, loaded: true));
    } catch (e, st) {
      if (isClosed) return;
      addError(e, st);
      emit(
        SettingsState(
          settings: state.settings,
          loading: false,
          loaded: _loaded,
          error: '설정을 불러오지 못했어요',
        ),
      );
    }
  }

  Future<void> setStartDay(int day) async {
    if (day < 1 || day > 31) return;
    await _update((s) => s.copyWith(startDay: day));
  }

  Future<void> setBudget(int? won) => _update(
    (s) =>
        won == null ? s.copyWith(clearBudget: true) : s.copyWith(budget: won),
  );

  Future<void> setDeleteRawText(bool v) =>
      _update((s) => s.copyWith(deleteRawText: v));

  Future<void> setHideAmounts(bool v) =>
      _update((s) => s.copyWith(hideAmounts: v));

  Future<void> setTheme(AppThemeId id) =>
      _update((s) => s.copyWith(themeId: id));

  Future<void> setThemeMode(AppThemeMode mode) =>
      _update((s) => s.copyWith(themeMode: mode));

  Future<void> saveFilters(List<FilterRule> filters) =>
      _update((s) => s.copyWith(filters: filters));

  Future<void> saveNames(NameRegistry names) =>
      _update((s) => s.copyWith(names: names));

  /// 허용 앱을 저장하고 네이티브 리스너에도 알린다.
  Future<void> setNotificationPackages(List<String> packages) async {
    final saved = await _update(
      (s) => s.copyWith(notificationPackages: packages),
    );
    if (!saved) return;
    try {
      await _bridge.setAllowedPackages(packages);
    } catch (e, st) {
      addError(e, st);
    }
  }

  /// 저장에 실패하면 이전 값을 유지하고 오류 문구를 낸다.
  /// 저장 뒤 갱신이 실패해도 저장은 끝났으므로 새 값을 유지한다.
  /// 설정을 읽지 못한 상태에서는 기본값으로 저장소를 덮어쓰지 않도록 저장하지 않는다.
  /// 저장했으면 true.
  Future<bool> _update(AppSettings Function(AppSettings) change) async {
    if (!_loaded) {
      await load();
      if (isClosed || !_loaded) return false;
    }
    final next = change(state.settings);
    try {
      await _repo.save(next);
    } catch (e, st) {
      if (isClosed) return false;
      addError(e, st);
      emit(
        SettingsState(
          settings: state.settings,
          loading: false,
          loaded: true,
          error: '저장하지 못했어요. 다시 시도해 주세요.',
        ),
      );
      return false;
    }
    if (isClosed) return true;
    emit(SettingsState(settings: next, loading: false, loaded: true));
    try {
      await _refresh();
    } catch (e, st) {
      addError(e, st);
    }
    return true;
  }
}
