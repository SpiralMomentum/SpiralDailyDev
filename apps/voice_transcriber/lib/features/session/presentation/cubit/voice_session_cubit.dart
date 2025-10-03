import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/voice_session_status.dart';
import '../../domain/usecases/complete_session_use_case.dart';
import '../../domain/usecases/copy_to_clipboard_use_case.dart';
import '../../domain/usecases/load_session_settings_use_case.dart';
import '../../domain/usecases/select_engine_use_case.dart';
import '../../domain/usecases/start_recording_use_case.dart';
import '../../domain/usecases/toggle_auto_copy_use_case.dart';
import '../../domain/value_objects/transcription_engine.dart';
import 'voice_session_state.dart';

class VoiceSessionCubit extends Cubit<VoiceSessionState> {
  VoiceSessionCubit(
    super.initialState,
    this._startRecordingUseCase,
    this._completeSessionUseCase,
    this._toggleAutoCopyUseCase,
    this._loadSessionSettingsUseCase,
    this._selectEngineUseCase,
    this._copyToClipboardUseCase,
  );

  final StartRecordingUseCase _startRecordingUseCase;
  final CompleteSessionUseCase _completeSessionUseCase;
  final ToggleAutoCopyUseCase _toggleAutoCopyUseCase;
  final LoadSessionSettingsUseCase _loadSessionSettingsUseCase;
  final SelectEngineUseCase _selectEngineUseCase;
  final CopyToClipboardUseCase _copyToClipboardUseCase;

  Future<void> initialize() async {
    final snapshot = await _loadSessionSettingsUseCase();
    emit(
      state.copyWith(
        autoCopyEnabled: snapshot.autoCopyEnabled,
        engine: snapshot.engine,
      ),
    );
  }

  Future<void> startRecording() async {
    emit(
      state.copyWith(
        status: VoiceSessionStatus.recording,
        errorMessage: null,
        result: null,
      ),
    );
    try {
      await _startRecordingUseCase();
    } catch (error) {
      emit(
        state.copyWith(
          status: VoiceSessionStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> completeSession() async {
    emit(
      state.copyWith(
        status: VoiceSessionStatus.processing,
        errorMessage: null,
      ),
    );

    try {
      final result = await _completeSessionUseCase();
      emit(
        state.copyWith(
          status: VoiceSessionStatus.completed,
          result: result,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: VoiceSessionStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> toggleAutoCopy() async {
    final enabled = await _toggleAutoCopyUseCase();
    emit(state.copyWith(autoCopyEnabled: enabled));
  }

  Future<void> selectEngine(TranscriptionEngine engine) async {
    await _selectEngineUseCase(engine);
    emit(state.copyWith(engine: engine));
  }

  void updateTranscription(String text) {
    final current = state.result;
    if (current == null) {
      return;
    }

    emit(
      state.copyWith(
        result: current.copyWith(text: text),
      ),
    );
  }

  Future<void> copyToClipboard(String text) {
    return _copyToClipboardUseCase(text);
  }
}
