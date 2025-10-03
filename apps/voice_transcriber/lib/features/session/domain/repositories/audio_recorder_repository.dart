import '../entities/audio_recording.dart';

abstract class AudioRecorderRepository {
  Future<void> start();

  Future<AudioRecording> stop();
}
