import '../repositories/voice_session_settings_repository.dart';

class ToggleAutoCopyUseCase {
  const ToggleAutoCopyUseCase(this._settingsRepository);

  final VoiceSessionSettingsRepository _settingsRepository;

  Future<bool> call() async {
    final current = await _settingsRepository.isAutoCopyEnabled();
    final next = !current;
    await _settingsRepository.setAutoCopyEnabled(next);
    return next;
  }
}
