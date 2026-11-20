import 'package:flutter_gemma/flutter_gemma.dart';

import 'llm_client.dart';

/// flutter_gemma(LiteRT-LM) 로 Gemma 4 E2B 를 기기 안에서 돌린다.
/// 모델은 처음 생성할 때 한 번 불러와 유지하고, 요청마다 새 대화(세션)를 열고 닫아 이전 요청 맥락이 섞이지 않게 한다.
/// 기기 하나에서 추론은 한 번에 하나만 돌도록 순서대로 처리한다.
class FlutterGemmaClient implements LlmClient {
  FlutterGemmaClient(
    this._activate, {
    this.maxTokens = 4096,
    this.temperature = 0.8,
    this.topK = 40,
    this.topP = 0.95,
    this.backend = PreferredBackend.cpu,
  });

  /// 설치된 모델을 활성 모델로 지정한다.
  final Future<void> Function() _activate;
  /// KV 캐시 크기. Gemma 4 E2B 파일의 프리필 신호 길이는 128/1024 라서, 1024 로 두면
  /// 128 토큰이 넘는 프롬프트가 프리필에서 실패한다 (DYNAMIC_UPDATE_SLICE). 4096 으로 둔다.
  final int maxTokens;
  final double temperature;
  final int topK;
  final double topP;
  final PreferredBackend backend;

  Future<InferenceModel>? _model;
  Future<void> _queue = Future.value();

  Future<InferenceModel> _load() async {
    await _activate();
    return FlutterGemma.getActiveModel(maxTokens: maxTokens, preferredBackend: backend);
  }

  Future<InferenceModel> _ensureModel() {
    final pending = _model ??= _load();
    return pending.catchError((Object e) {
      _model = null;
      throw e;
    });
  }

  @override
  Future<String> generate(String prompt, {required int seed}) {
    final run = _queue.then((_) async {
      final model = await _ensureModel();
      final session = await model.createSession(
        temperature: temperature,
        randomSeed: seed,
        topK: topK,
        topP: topP,
      );
      try {
        await session.addQueryChunk(Message.text(text: prompt, isUser: true));
        return await session.getResponse();
      } finally {
        await session.close();
      }
    });
    _queue = run.then((_) {}, onError: (_) {});
    return run;
  }

  /// 모델을 미리 불러온다 (첫 결과 대기 시간 단축).
  Future<void> warmUp() => _ensureModel();
}
