import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_ai_assistant/src/assistant_controller.dart';
import 'package:voice_ai_assistant/src/voice_assistant_app.dart';

void main() {
  testWidgets('starts a hands-free conversation from the main control', (
    tester,
  ) async {
    final controller = AssistantController(
      audioFocus: _Audio(),
      speech: _Speech(),
      notes: MemoryNoteRepository(),
    );
    await tester.pumpWidget(VoiceAssistantApp(controller: controller));

    expect(find.text('말할 준비가 됐어요'), findsOneWidget);
    await tester.tap(find.byKey(const Key('voiceButton')));
    await tester.pump();
    expect(find.text('듣고 있어요'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('원본 음성과 텍스트를 저장했어요'), findsOneWidget);
    expect(find.text('말할 준비가 됐어요'), findsOneWidget);
  });
}

class _Audio implements AudioFocusGateway {
  @override
  Future<void> duckMusic() async {}
  @override
  Future<void> restoreMusic() async {}
}

class _Speech implements SpeechGateway {
  @override
  Future<SpeechCapture> listen({required bool noiseSuppression}) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return const SpeechCapture(
      transcript: '인터벌 러닝 아이디어',
      audioPath: '/recordings/interval.m4a',
    );
  }

  @override
  Future<void> speak(String text) async {}
}
