import '../entities/transcription_result.dart';
import '../repositories/audio_recorder_repository.dart';
import '../repositories/clipboard_repository.dart';
import '../repositories/speech_to_text_gateway.dart';
import '../repositories/voice_session_settings_repository.dart';

class CompleteSessionUseCase {
  CompleteSessionUseCase(
    this._recorderRepository,
    this._speechToTextGateway,
    this._clipboardRepository,
    this._settingsRepository,
  );

  final AudioRecorderRepository _recorderRepository;
  final SpeechToTextGateway _speechToTextGateway;
  final ClipboardRepository _clipboardRepository;
  final VoiceSessionSettingsRepository _settingsRepository;

  Future<TranscriptionResult> call() async {
    final recording = await _recorderRepository.stop();
    final rawResult = await _speechToTextGateway.transcribe(recording);
    final shouldCopy = await _settingsRepository.isAutoCopyEnabled();

    if (shouldCopy) {
      await _clipboardRepository.copy(rawResult.text);
    }

    return rawResult.copyWith(
      copiedToClipboard: shouldCopy,
    );
  }
}
