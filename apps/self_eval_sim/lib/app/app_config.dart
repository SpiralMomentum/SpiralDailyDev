import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../features/model_pack/data/model_installer.dart';
import '../features/monetization/data/monetization_impl.dart';
import '../features/monetization/domain/monetization.dart';
import '../features/share/data/share_impl.dart';

/// 앱 외부 의존과 운영 수치를 한곳에 모은다. 통합 테스트는 이 값을 바꿔 실행 조건을 고정한다.
class AppConfig {
  AppConfig({
    Random? random,
    DateTime Function()? clock,
    Future<Directory> Function()? documentsDirectory,
    Future<Directory> Function()? temporaryDirectory,
    AssetBundle? bundle,
    ModelSpec? modelSpec,
    ModelInstaller? modelInstaller,
    ModelSizeProbe? modelSizeProbe,
    ConnectivityRepository? connectivity,
    ShareSink? shareSink,
    this.maxModelBytes = defaultMaxModelBytes,
    this.adDuration = const Duration(seconds: 5),
  })  : random = random ?? Random(),
        clock = clock ?? DateTime.now,
        documentsDirectory = documentsDirectory ?? getApplicationDocumentsDirectory,
        temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
        bundle = bundle ?? rootBundle,
        modelSpec = modelSpec ?? defaultModelSpec,
        modelInstaller = modelInstaller ?? const FlutterGemmaInstaller(),
        modelSizeProbe = modelSizeProbe ?? HttpModelSizeProbe(),
        connectivity = connectivity ?? const DnsConnectivityRepository(),
        shareSink = shareSink ?? const SharePlusSink();

  /// 모델 단독 용량 상한. 명세에서 수치가 미정이라 임시값(3 GiB)을 둔다. Gemma 4 E2B 파일은 2.41 GiB.
  static const int defaultMaxModelBytes = 3 * 1024 * 1024 * 1024;

  /// 모델 주소 재정의 (사내 미러, 테스트용 로컬 서버). 파일 이름은 원본과 같아야 한다.
  static const String modelUrlOverride = String.fromEnvironment('MODEL_URL');

  static ModelSpec get defaultModelSpec => modelUrlOverride.isEmpty
      ? ModelSpec.gemma4E2b
      : ModelSpec(url: modelUrlOverride, expectedBytes: ModelSpec.gemma4E2b.expectedBytes);

  final Random random;
  final DateTime Function() clock;
  final Future<Directory> Function() documentsDirectory;
  final Future<Directory> Function() temporaryDirectory;
  final AssetBundle bundle;
  final ModelSpec modelSpec;
  final ModelInstaller modelInstaller;
  final ModelSizeProbe modelSizeProbe;
  final ConnectivityRepository connectivity;
  final ShareSink shareSink;
  final int maxModelBytes;

  /// 시뮬레이션 광고 길이.
  final Duration adDuration;
}
