import 'dart:math';

import '../../domain/entities/audio_recording.dart';

class FakeAudioRecorderDataSource {
  Future<void> start() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  Future<AudioRecording> stop() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final random = Random();
    return AudioRecording(
      bytes: List<int>.generate(200, (_) => random.nextInt(255)),
      duration: Duration(milliseconds: 600 + random.nextInt(1600)),
    );
  }
}
