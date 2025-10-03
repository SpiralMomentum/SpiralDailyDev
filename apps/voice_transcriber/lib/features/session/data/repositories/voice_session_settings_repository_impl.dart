import '../../domain/repositories/voice_session_settings_repository.dart';
import '../../domain/value_objects/transcription_engine.dart';

class VoiceSessionSettingsRepositoryImpl
    implements VoiceSessionSettingsRepository {
  VoiceSessionSettingsRepositoryImpl({
    bool autoCopyEnabled = true,
    TranscriptionEngine engine = TranscriptionEngine.openAi,
  })  : _autoCopyEnabled = autoCopyEnabled,
        _engine = engine;

  bool _autoCopyEnabled;
  TranscriptionEngine _engine;

  @override
  Future<bool> isAutoCopyEnabled() async {
    return _autoCopyEnabled;
  }

  @override
  Future<void> setAutoCopyEnabled(bool value) async {
    _autoCopyEnabled = value;
  }

  @override
  Future<TranscriptionEngine> currentEngine() async {
    return _engine;
  }

  @override
  Future<void> selectEngine(TranscriptionEngine engine) async {
    _engine = engine;
  }
}
