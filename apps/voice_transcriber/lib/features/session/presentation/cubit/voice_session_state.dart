import 'package:equatable/equatable.dart';

import '../../domain/entities/transcription_result.dart';
import '../../domain/entities/voice_session_status.dart';
import '../../domain/value_objects/transcription_engine.dart';

class VoiceSessionState extends Equatable {
  const VoiceSessionState({
    this.status = VoiceSessionStatus.idle,
    this.autoCopyEnabled = true,
    this.engine = TranscriptionEngine.openAi,
    this.result,
    this.errorMessage,
  });

  final VoiceSessionStatus status;
  final bool autoCopyEnabled;
  final TranscriptionEngine engine;
  final TranscriptionResult? result;
  final String? errorMessage;

  VoiceSessionState copyWith({
    VoiceSessionStatus? status,
    bool? autoCopyEnabled,
    TranscriptionEngine? engine,
    TranscriptionResult? result,
    String? errorMessage,
  }) {
    return VoiceSessionState(
      status: status ?? this.status,
      autoCopyEnabled: autoCopyEnabled ?? this.autoCopyEnabled,
      engine: engine ?? this.engine,
      result: result ?? this.result,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        autoCopyEnabled,
        engine,
        result,
        errorMessage,
      ];
}
