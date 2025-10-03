import '../../domain/entities/audio_recording.dart';

class FakeLocalSpeechToTextDataSource {
  Future<String> transcribe(AudioRecording recording) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return '로컬 모델이 ${recording.duration.inSeconds}초 분량의 음성을 처리했습니다.';
  }
}
