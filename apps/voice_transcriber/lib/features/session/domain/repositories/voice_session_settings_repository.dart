import '../value_objects/transcription_engine.dart';

abstract class VoiceSessionSettingsRepository {
  Future<bool> isAutoCopyEnabled();

  Future<void> setAutoCopyEnabled(bool value);

  Future<TranscriptionEngine> currentEngine();

  Future<void> selectEngine(TranscriptionEngine engine);
}
