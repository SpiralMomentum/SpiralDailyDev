import '../../domain/entities/audio_recording.dart';
import '../../domain/repositories/audio_recorder_repository.dart';
import '../datasources/fake_audio_recorder_datasource.dart';

class AudioRecorderRepositoryImpl implements AudioRecorderRepository {
  AudioRecorderRepositoryImpl(this._dataSource);

  final FakeAudioRecorderDataSource _dataSource;

  @override
  Future<void> start() {
    return _dataSource.start();
  }

  @override
  Future<AudioRecording> stop() {
    return _dataSource.stop();
  }
}
