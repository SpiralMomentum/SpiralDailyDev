import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../ingest/domain/ingest.dart';
import '../../message_filter/domain/raw_message.dart';
import '../domain/summary.dart';

/// 수동 입력 결과.
enum ManualResult { stored, filtered, failed }

final class HomeState extends Equatable {
  const HomeState({this.summary, this.loading = true});

  final LedgerSummary? summary;
  final bool loading;

  @override
  List<Object?> get props => [summary, loading];
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._deps) : super(const HomeState());

  final IngestDeps _deps;

  /// 요약을 다시 계산한다. 위젯 갱신과 예산 알림도 함께 처리된다.
  Future<void> load() async {
    emit(HomeState(summary: state.summary));
    try {
      final summary = await refreshOutputs(_deps);
      emit(HomeState(summary: summary, loading: false));
    } catch (e, st) {
      emit(HomeState(summary: state.summary, loading: false));
      addError(e, st);
    }
  }

  /// 붙여넣은 문자를 수동 입력으로 수집하고 요약을 다시 읽는다.
  /// 예외가 나면 실패로 본다(저장 뒤 알림만 실패했을 수도 있지만,
  /// 다시 붙여넣어도 중복으로 처리되므로 합계가 두 번 잡히지 않는다).
  Future<ManualResult> addManual(String text) async {
    ManualResult result;
    try {
      final (ingested, _) = await ingestMessage(
        RawMessage(
          text: text,
          receivedAt: _deps.now(),
          source: MessageSource.manual,
        ),
        _deps,
      );
      result = ingested == IngestResult.stored
          ? ManualResult.stored
          : ManualResult.filtered;
    } catch (e, st) {
      addError(e, st);
      result = ManualResult.failed;
    }
    await load();
    return result;
  }
}
