import '../repositories/voice_session_settings_repository.dart';
import '../value_objects/transcription_engine.dart';

class SessionSettingsSnapshot {
  const SessionSettingsSnapshot({
    required this.autoCopyEnabled,
    required this.engine,
  });

  final bool autoCopyEnabled;
  final TranscriptionEngine engine;
}

class LoadSessionSettingsUseCase {
  const LoadSessionSettingsUseCase(this._settingsRepository);

  final VoiceSessionSettingsRepository _settingsRepository;

  Future<SessionSettingsSnapshot> call() async {
    final autoCopy = await _settingsRepository.isAutoCopyEnabled();
    final engine = await _settingsRepository.currentEngine();
    return SessionSettingsSnapshot(autoCopyEnabled: autoCopy, engine: engine);
  }
}
