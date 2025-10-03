import 'dart:math';

import '../../domain/entities/audio_recording.dart';

class FakeOpenAiSpeechToTextDataSource {
  Future<String> transcribe(AudioRecording recording) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    final samples = <String>[
      '회의록 초안입니다. 주요 안건은 음성 인식 품질 개선과 클립보드 자동 복사 고도화였습니다.',
      '다음 작업을 위해 코드를 정리하고, 테스트 커버리지를 80% 이상 유지하세요.',
      'OpenAI 음성 모델과 자체 모델의 비교를 위해 실험 로그를 기록합니다.',
    ];
    return samples[Random().nextInt(samples.length)];
  }
}
