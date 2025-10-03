import '../repositories/audio_recorder_repository.dart';

class StartRecordingUseCase {
  const StartRecordingUseCase(this._recorderRepository);

  final AudioRecorderRepository _recorderRepository;

  Future<void> call() {
    return _recorderRepository.start();
  }
}
