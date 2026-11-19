import 'dart:convert';
import 'dart:math';

import 'package:utils/utils.dart';

import '../../domain/entities/accumulation.dart';
import '../../domain/entities/evaluation.dart';
import '../../domain/repositories/narration_engine.dart';

/// 앱에 포함된 템플릿 팩(`assets/narration/templates.json`)으로 대사를 만드는 엔진.
/// 온디바이스 모델이 실패하거나 규칙을 통과하지 못한 출력을 낼 때의 대체 수단이다.
/// 기본 결과 대사는 콘텐츠 대사([BaseNarrationRequest.fallbackLines])를 그대로 쓴다.
/// 발현 대사의 마지막 줄은 누적 유형 설명이다 (유형이 없으면 템플릿 맺음말).
class TemplateNarrationEngine implements NarrationEngine {
  TemplateNarrationEngine(this._readPack);

  /// 템플릿 팩 JSON 원문을 읽는다.
  final Future<String> Function() _readPack;
  Map<String, dynamic>? _pack;

  Future<Map<String, dynamic>> _languages() async {
    final pack = _pack ??=
        jsonDecode(await _readPack()) as Map<String, dynamic>;
    return pack['languages'] as Map<String, dynamic>;
  }

  @override
  Future<Result<Narration>> baseLines(
    BaseNarrationRequest request,
    Random random,
  ) async => Success(
    Narration(lines: request.fallbackLines, source: NarrationSource.template),
  );

  @override
  Future<Result<ManifestationText>> manifestation(
    ManifestationRequest request,
    Random random,
  ) => guardAsync(
    action: () async {
      final t =
          (await _languages())[request.languageCode] as Map<String, dynamic>;
      return compose(
        t,
        request.form,
        request.materials,
        random,
        profile: request.profile,
      );
    },
    onError: (e, st) => ParsingFailure(
      message: 'pack:${request.languageCode}',
      cause: e,
      stackTrace: st,
    ),
  );

  static String _pick(Map<String, dynamic> t, String key, Random random) {
    final list = (t[key] as List).cast<String>();
    return list[random.nextInt(list.length)];
  }

  static String fill(String template, ResolvedMaterial m) => template
      .replaceAll('{ago}', '${m.ago}')
      .replaceAll('{channel}', m.channelName)
      .replaceAll('{choice}', m.choiceText);

  static ManifestationText compose(
    Map<String, dynamic> t,
    ManifestationForm form,
    List<ResolvedMaterial> materials,
    Random random, {
    TypeProfile? profile,
  }) {
    final intro = _pick(
      t,
      form == ManifestationForm.mixed ? 'mixed.intro' : 'separate.intro',
      random,
    );
    final recalls = [
      for (final m in materials)
        fill(
          _pick(
            t,
            m.kind == MaterialKind.manifestation
                ? 'recall.manifest'
                : 'recall.attempt',
            random,
          ),
          m,
        ),
    ];
    return ManifestationText(
      lines: [
        intro,
        ...recalls,
        profile?.description ?? _pick(t, 'close', random),
      ],
      separateSpeaker: t['separate.speaker'] as String,
      separatePlace: t['separate.place'] as String,
    );
  }
}
