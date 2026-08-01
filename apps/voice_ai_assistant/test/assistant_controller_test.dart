import 'package:flutter_test/flutter_test.dart';
import 'package:voice_ai_assistant/src/assistant_controller.dart';

void main() {
  test('ducks music, captures an idea, speaks, then restores music', () async {
    final audio = _FakeAudioFocus();
    final speech = _FakeSpeech();
    final notes = MemoryNoteRepository();
    final controller = AssistantController(
      audioFocus: audio,
      speech: speech,
      notes: notes,
    );

    await controller.startConversation();

    expect(audio.events, ['duck', 'restore']);
    expect(speech.noiseSuppressionEnabled, isTrue);
    expect(speech.spoken, isNotEmpty);
    expect(notes.notes.single.transcript, '새 러닝 아이디어');
    expect(notes.notes.single.audioPath, '/recordings/idea.m4a');
    expect(controller.phase, AssistantPhase.ready);
    expect(controller.musicDucked, isFalse);
  });

  test('restores music when speech recognition fails', () async {
    final audio = _FakeAudioFocus();
    final controller = AssistantController(
      audioFocus: audio,
      speech: _FakeSpeech(shouldFail: true),
      notes: MemoryNoteRepository(),
    );

    await expectLater(controller.startConversation(), throwsStateError);

    expect(audio.events, ['duck', 'restore']);
    expect(controller.phase, AssistantPhase.ready);
    expect(controller.musicDucked, isFalse);
    expect(controller.lastError, isNotNull);
  });

  test('runs every conversation phase in order', () async {
    final controller = AssistantController(
      audioFocus: _FakeAudioFocus(),
      speech: _FakeSpeech(),
      notes: MemoryNoteRepository(),
    );
    final phases = <AssistantPhase>[];
    controller.addListener(() => phases.add(controller.phase));

    await controller.startConversation();

    expect(
      phases,
      containsAllInOrder([
        AssistantPhase.listening,
        AssistantPhase.thinking,
        AssistantPhase.speaking,
        AssistantPhase.ready,
      ]),
    );
  });

  test('returns to ready even when restoring audio focus fails', () async {
    final controller = AssistantController(
      audioFocus: _FakeAudioFocus(restoreShouldFail: true),
      speech: _FakeSpeech(),
      notes: MemoryNoteRepository(),
    );

    await expectLater(controller.startConversation(), throwsStateError);

    expect(controller.phase, AssistantPhase.ready);
    expect(controller.musicDucked, isFalse);
  });
}

class _FakeAudioFocus implements AudioFocusGateway {
  _FakeAudioFocus({this.restoreShouldFail = false});

  final bool restoreShouldFail;
  final events = <String>[];

  @override
  Future<void> duckMusic() async => events.add('duck');

  @override
  Future<void> restoreMusic() async {
    events.add('restore');
    if (restoreShouldFail) throw StateError('audio focus unavailable');
  }
}

class _FakeSpeech implements SpeechGateway {
  _FakeSpeech({this.shouldFail = false});
  final bool shouldFail;
  bool noiseSuppressionEnabled = false;
  String spoken = '';

  @override
  Future<SpeechCapture> listen({required bool noiseSuppression}) async {
    noiseSuppressionEnabled = noiseSuppression;
    if (shouldFail) throw StateError('microphone unavailable');
    return const SpeechCapture(
      transcript: '새 러닝 아이디어',
      audioPath: '/recordings/idea.m4a',
    );
  }

  @override
  Future<void> speak(String text) async => spoken = text;
}
