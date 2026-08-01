import 'dart:async';

import 'package:flutter/foundation.dart';

enum AssistantPhase { ready, listening, thinking, speaking }

@immutable
class VoiceNote {
  const VoiceNote({
    required this.title,
    required this.transcript,
    required this.audioPath,
    required this.createdAt,
  });

  final String title;
  final String transcript;

  /// 실제 녹음 파일이 생성된 경우에만 설정됩니다.
  final String? audioPath;
  final DateTime createdAt;
}

abstract interface class AudioFocusGateway {
  Future<void> duckMusic();
  Future<void> restoreMusic();
}

abstract interface class SpeechGateway {
  Future<SpeechCapture> listen({required bool noiseSuppression});
  Future<void> speak(String text);
}

@immutable
class SpeechCapture {
  const SpeechCapture({required this.transcript, this.audioPath});

  final String transcript;
  final String? audioPath;
}

abstract interface class NoteRepository {
  Future<void> save(VoiceNote note);
}

class AssistantController extends ChangeNotifier {
  AssistantController({
    required AudioFocusGateway audioFocus,
    required SpeechGateway speech,
    required NoteRepository notes,
  }) : _audioFocus = audioFocus,
       _speech = speech,
       _notes = notes;

  final AudioFocusGateway _audioFocus;
  final SpeechGateway _speech;
  final NoteRepository _notes;

  AssistantPhase phase = AssistantPhase.ready;
  String transcript = '';
  String response = '';
  bool musicDucked = false;
  bool earphonesConnected = true;
  bool saveAsIdea = true;
  VoiceNote? latestNote;
  String? lastError;

  bool get isBusy => phase != AssistantPhase.ready;

  Future<void> startConversation() async {
    if (isBusy) return;
    try {
      await _audioFocus.duckMusic();
      musicDucked = true;
      phase = AssistantPhase.listening;
      transcript = '';
      response = '';
      lastError = null;
      notifyListeners();

      final capture = await _speech.listen(noiseSuppression: true);
      transcript = capture.transcript;
      phase = AssistantPhase.thinking;
      notifyListeners();

      response = _createResponse(transcript);
      if (saveAsIdea) {
        final note = VoiceNote(
          title: _createTitle(transcript),
          transcript: transcript,
          audioPath: capture.audioPath,
          createdAt: DateTime.now(),
        );
        await _notes.save(note);
        latestNote = note;
      }

      phase = AssistantPhase.speaking;
      notifyListeners();
      await _speech.speak(response);
    } catch (_) {
      lastError = '음성 처리를 완료하지 못했어요. 다시 시도해 주세요.';
      rethrow;
    } finally {
      try {
        await _audioFocus.restoreMusic();
      } finally {
        musicDucked = false;
        phase = AssistantPhase.ready;
        notifyListeners();
      }
    }
  }

  void toggleIdeaMode() {
    if (isBusy) return;
    saveAsIdea = !saveAsIdea;
    notifyListeners();
  }

  static String _createTitle(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return '새 음성 아이디어';
    return normalized.length > 20
        ? '${normalized.substring(0, 20)}…'
        : normalized;
  }

  static String _createResponse(String value) => value.trim().isEmpty
      ? '잘 듣지 못했어요. 다시 말씀해 주세요.'
      : '좋아요. 핵심 아이디어로 정리해 두었어요. 운동이 끝난 뒤 바로 확인할 수 있어요.';
}

class DemoAudioFocusGateway implements AudioFocusGateway {
  @override
  Future<void> duckMusic() async =>
      Future<void>.delayed(const Duration(milliseconds: 250));

  @override
  Future<void> restoreMusic() async =>
      Future<void>.delayed(const Duration(milliseconds: 180));
}

class DemoSpeechGateway implements SpeechGateway {
  @override
  Future<SpeechCapture> listen({required bool noiseSuppression}) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return const SpeechCapture(transcript: '러닝할 때 떠오른 아이디어를 주제별로 묶어서 보여줘');
  }

  @override
  Future<void> speak(String text) async =>
      Future<void>.delayed(const Duration(seconds: 2));
}

class MemoryNoteRepository implements NoteRepository {
  final List<VoiceNote> notes = <VoiceNote>[];

  @override
  Future<void> save(VoiceNote note) async => notes.insert(0, note);
}
