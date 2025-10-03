import '../repositories/voice_session_settings_repository.dart';
import '../value_objects/transcription_engine.dart';

class SelectEngineUseCase {
  const SelectEngineUseCase(this._settingsRepository);

  final VoiceSessionSettingsRepository _settingsRepository;

  Future<void> call(TranscriptionEngine engine) {
    return _settingsRepository.selectEngine(engine);
  }
}
