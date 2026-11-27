import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../ingest/domain/ingest.dart';
import '../../message_filter/domain/raw_message.dart';
import '../domain/summary.dart';

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
  /// 알림 실패는 저장을 되돌리지 않으므로 저장된 것으로 본다.
  Future<IngestResult> addManual(String text) async {
    var result = IngestResult.stored;
    try {
      (result, _) = await ingestMessage(
        RawMessage(
          text: text,
          receivedAt: _deps.now(),
          source: MessageSource.manual,
        ),
        _deps,
      );
    } catch (e, st) {
      addError(e, st);
    }
    await load();
    return result;
  }
}
