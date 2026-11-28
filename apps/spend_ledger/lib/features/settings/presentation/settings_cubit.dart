import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../ingest/data/android_bridge.dart';
import '../../message_filter/domain/filter_rule.dart';
import '../../message_filter/domain/name_registry.dart';
import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

final class SettingsState extends Equatable {
  const SettingsState({
    this.settings = const AppSettings(),
    this.loading = true,
    this.error,
  });

  final AppSettings settings;
  final bool loading;

  /// 마지막 읽기·저장이 실패했을 때 보여 줄 문구. 설정값은 이전 값을 유지한다.
  final String? error;

  @override
  List<Object?> get props => [settings, loading, error];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(
    this._repo,
    this._refresh, {
    AndroidBridge bridge = const AndroidBridge(),
  }) : _bridge = bridge,
       super(const SettingsState());

  final SettingsRepository _repo;
  final AndroidBridge _bridge;
  final Future<void> Function() _refresh;

  Future<void> load() async {
    try {
      emit(SettingsState(settings: await _repo.load(), loading: false));
    } catch (e, st) {
      addError(e, st);
      emit(
        SettingsState(
          settings: state.settings,
          loading: false,
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

  Future<void> saveFilters(List<FilterRule> filters) =>
      _update((s) => s.copyWith(filters: filters));

  Future<void> saveNames(NameRegistry names) =>
      _update((s) => s.copyWith(names: names));

  /// 허용 앱을 저장하고 네이티브 리스너에도 알린다.
  Future<void> setNotificationPackages(List<String> packages) async {
    await _update((s) => s.copyWith(notificationPackages: packages));
    if (state.settings.notificationPackages != packages) return;
    try {
      await _bridge.setAllowedPackages(packages);
    } catch (e, st) {
      addError(e, st);
    }
  }

  /// 저장에 실패하면 이전 값을 유지하고 오류 문구를 낸다.
  /// 저장 뒤 갱신이 실패해도 저장은 끝났으므로 새 값을 유지한다.
  Future<void> _update(AppSettings Function(AppSettings) change) async {
    final next = change(state.settings);
    try {
      await _repo.save(next);
    } catch (e, st) {
      addError(e, st);
      emit(
        SettingsState(
          settings: state.settings,
          loading: false,
          error: '저장하지 못했어요. 다시 시도해 주세요.',
        ),
      );
      return;
    }
    emit(SettingsState(settings: next, loading: false));
    try {
      await _refresh();
    } catch (e, st) {
      addError(e, st);
    }
  }
}
