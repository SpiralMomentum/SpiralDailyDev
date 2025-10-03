import 'package:uuid/uuid.dart';

import '../../domain/entities/audio_recording.dart';
import '../../domain/entities/transcription_result.dart';
import '../../domain/repositories/speech_to_text_gateway.dart';
import '../../domain/repositories/voice_session_settings_repository.dart';
import '../../domain/value_objects/transcription_engine.dart';
import '../datasources/fake_local_speech_to_text_datasource.dart';
import '../datasources/fake_openai_speech_to_text_datasource.dart';

class SpeechToTextGatewayImpl implements SpeechToTextGateway {
  SpeechToTextGatewayImpl(
    this._openAiDataSource,
    this._localDataSource,
    this._settingsRepository,
  );

  final FakeOpenAiSpeechToTextDataSource _openAiDataSource;
  final FakeLocalSpeechToTextDataSource _localDataSource;
  final VoiceSessionSettingsRepository _settingsRepository;
  final Uuid _uuid = const Uuid();

  @override
  Future<TranscriptionResult> transcribe(AudioRecording recording) async {
    final engine = await _settingsRepository.currentEngine();
    final text = await _transcribeByEngine(engine, recording);
    return TranscriptionResult(
      id: _uuid.v4(),
      text: text,
      engineLabel: engine.label,
      copiedToClipboard: false,
    );
  }

  Future<String> _transcribeByEngine(
    TranscriptionEngine engine,
    AudioRecording recording,
  ) {
    switch (engine) {
      case TranscriptionEngine.openAi:
        return _openAiDataSource.transcribe(recording);
      case TranscriptionEngine.local:
        return _localDataSource.transcribe(recording);
    }
  }
}
