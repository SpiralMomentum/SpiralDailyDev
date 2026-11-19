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
      (languages[languageCode] ?? languages['en']) as Map<String, dynamic>,
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
  }) async {
    final raw = await _client
        .generate(prompt, seed: random.nextInt(1 << 31))
        .timeout(timeout);
    final lines = LineSanitizer.clean(
      raw,
      title: title,
      maxLength: spec.maxLength,
      maxLines: maxLines,
      banned: spec.banned,
      avoid: avoid,
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
      final lines = await _run(
        PromptBuilder.base(spec, request),
        random: random,
        title: request.title,
        spec: spec,
        maxLines: spec.baseLines,
        minLines: spec.minBaseLines,
        avoid: request.examples,
      );
      return Narration(lines: lines, source: NarrationSource.model);
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
