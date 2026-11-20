import 'dart:convert';
import 'dart:math';

import 'package:utils/utils.dart';

import '../../domain/entities/evaluation.dart';
import '../../domain/repositories/narration_engine.dart';
import 'line_sanitizer.dart';
import 'llm_client.dart';
import 'prompt_builder.dart';

/// 출력이 규칙을 통과하지 못함.
class NarrationRejected extends ParsingFailure {
  const NarrationRejected(String raw) : super(message: 'rejected', cause: raw);
}

/// 온디바이스 LLM 으로 결과/발현 대사를 만든다.
class LlmNarrationEngine implements NarrationEngine {
  LlmNarrationEngine(
    this._client,
    this._readPrompts, {
    this.timeout = const Duration(seconds: 60),
  });

  final LlmClient _client;

  /// `assets/narration/prompts.json` 원문.
  final Future<String> Function() _readPrompts;
  final Duration timeout;
  Map<String, dynamic>? _prompts;

  Future<PromptSpec> _spec(String languageCode) async {
    final prompts = _prompts ??=
        jsonDecode(await _readPrompts()) as Map<String, dynamic>;
    final languages = prompts['languages'] as Map<String, dynamic>;
    return PromptSpec(
      (languages[languageCode] ?? languages['ko']) as Map<String, dynamic>,
    );
  }

  Future<List<String>> _run(
    String prompt, {
    required Random random,
    required String title,
    required PromptSpec spec,
    required int maxLines,
    required int minLines,
    List<String> avoid = const [],
    List<String> bannedExtra = const [],
    List<String> echoes = const [],
    RegExp? ending,
  }) async {
    final raw = await _client
        .generate(prompt, seed: random.nextInt(1 << 31))
        .timeout(timeout);
    final lines = LineSanitizer.clean(
      raw,
      title: title,
      maxLength: spec.maxLength,
      maxLines: maxLines,
      banned: [...spec.banned, ...bannedExtra.map(PromptSpec.pattern)],
      avoid: avoid,
      echoes: echoes,
      echoLength: spec.echoLength,
      ending: ending,
    );
    if (lines.length < minLines) throw NarrationRejected(raw);
    return lines;
  }

  static Failure _failure(Object e, StackTrace st) => e is Failure
      ? e
      : ParsingFailure(message: 'llm', cause: e, stackTrace: st);

  @override
  Future<Result<Narration>> baseLines(
    BaseNarrationRequest request,
    Random random,
  ) => guardAsync(
    action: () async {
      final spec = await _spec(request.languageCode);
      Future<List<String>> once() => _run(
        PromptBuilder.base(spec, request),
        random: random,
        title: request.title,
        spec: spec,
        maxLines: request.story ? spec.storyBaseLines : spec.baseLines,
        minLines: request.story ? spec.minStoryBaseLines : spec.minBaseLines,
        avoid: request.examples,
        bannedExtra: request.avoid,
        echoes: request.echoes,
        ending: request.ending.isEmpty
            ? null
            : PromptSpec.pattern(request.ending),
      );
      // 이야기 대사는 한 줄이라 규칙에 걸리면 통째로 빠진다. 정한 횟수만큼 새 시드로 다시 만든다.
      final retries = request.story ? spec.storyRetries : 0;
      for (var i = 0; i < retries; i++) {
        try {
          return Narration(lines: await once(), source: NarrationSource.model);
        } on NarrationRejected {
          continue;
        }
      }
      return Narration(lines: await once(), source: NarrationSource.model);
    },
    onError: _failure,
  );

  @override
  Future<Result<ManifestationText>> manifestation(
    ManifestationRequest request,
    Random random,
  ) => guardAsync(
    action: () async {
      final spec = await _spec(request.languageCode);
      final lines = await _run(
        PromptBuilder.manifestation(spec, request),
        random: random,
        title: request.title,
        spec: spec,
        maxLines: spec.manifestLines,
        minLines: spec.minManifestLines,
        avoid: request.examples,
        bannedExtra: request.avoid,
      );
      return ManifestationText(
        lines: lines,
        separateSpeaker: spec.separateVoice,
        separatePlace: '',
        source: NarrationSource.model,
      );
    },
    onError: _failure,
  );
}
