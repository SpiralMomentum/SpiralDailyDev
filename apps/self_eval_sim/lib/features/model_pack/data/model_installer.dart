import 'dart:io';

import 'package:flutter_gemma/flutter_gemma.dart';

/// 내려받을 온디바이스 모델.
final class ModelSpec {
  const ModelSpec({required this.url, required this.expectedBytes});

  /// Gemma 4 E2B (LiteRT-LM, CPU/GPU 공용판). 리비전을 고정해 같은 파일만 받는다.
  static const gemma4E2b = ModelSpec(
    url: 'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/'
        '2d74ac41a33d7da82f39f7d5720a04c68514a103/gemma-4-E2B-it.litertlm',
    expectedBytes: 2588147712,
  );

  final String url;

  /// 받기 전 크기를 알 수 없을 때 상한 검사에 쓰는 값.
  final int expectedBytes;

  String get fileName => Uri.parse(url).pathSegments.last;
}

/// 받기 전 파일 크기 확인 (HEAD).
abstract interface class ModelSizeProbe {
  Future<int?> contentLength(String url);
}

class HttpModelSizeProbe implements ModelSizeProbe {
  HttpModelSizeProbe({HttpClient? client}) : _client = client ?? HttpClient();

  final HttpClient _client;

  @override
  Future<int?> contentLength(String url) async {
    final request = await _client.headUrl(Uri.parse(url));
    final response = await request.close();
    await response.drain<void>();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('status ${response.statusCode}', uri: Uri.parse(url));
    }
    return response.contentLength < 0 ? null : response.contentLength;
  }
}

/// 모델 런타임 설치기 경계.
abstract interface class ModelInstaller {
  Future<bool> isInstalled(ModelSpec spec);

  /// 진행률(0~100)을 흘리며 내려받아 설치하고, 설치한 모델을 활성 모델로 지정한다.
  Stream<int> install(ModelSpec spec);

  /// 이미 설치된 모델을 활성 모델로 지정한다 (앱 재시작 후 첫 생성 전에 필요).
  Future<void> activate(ModelSpec spec);
}

/// flutter_gemma 설치기. 500MB 가 넘는 파일은 Android 포그라운드 서비스로 받고 실패 시 재시도한다.
class FlutterGemmaInstaller implements ModelInstaller {
  const FlutterGemmaInstaller();

  InferenceInstallationBuilder _builder(ModelSpec spec) => FlutterGemma.installModel(
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
      ).fromNetwork(spec.url);

  @override
  Future<bool> isInstalled(ModelSpec spec) => FlutterGemma.isModelInstalled(spec.fileName);

  @override
  Stream<int> install(ModelSpec spec) async* {
    final progress = <int>[];
    var done = false;
    Object? error;
    StackTrace? errorStack;
    final future = _builder(spec)
        .withProgress(progress.add)
        .install()
        .then((_) => done = true, onError: (Object e, StackTrace st) {
      error = e;
      errorStack = st;
      done = true;
    });
    var last = -1;
    while (!done) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (progress.isNotEmpty && progress.last != last) yield last = progress.last;
    }
    await future;
    if (error != null) Error.throwWithStackTrace(error!, errorStack!);
    if (last != 100) yield 100;
  }

  @override
  Future<void> activate(ModelSpec spec) => _builder(spec).install();
}
