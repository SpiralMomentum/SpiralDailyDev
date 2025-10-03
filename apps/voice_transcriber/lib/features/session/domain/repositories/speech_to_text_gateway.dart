import '../entities/audio_recording.dart';
import '../entities/transcription_result.dart';

abstract class SpeechToTextGateway {
  Future<TranscriptionResult> transcribe(AudioRecording recording);
}
