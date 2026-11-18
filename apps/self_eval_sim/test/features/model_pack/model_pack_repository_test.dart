import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/model_pack/data/model_installer.dart';
import 'package:self_eval_sim/features/model_pack/data/model_pack_repository_impl.dart';
import 'package:self_eval_sim/features/model_pack/domain/model_pack.dart';
import 'package:utils/utils.dart';

const spec = ModelSpec(url: 'https://example.com/models/gemma.litertlm', expectedBytes: 1000);

class _Probe implements ModelSizeProbe {
  _Probe(this.length, {this.fail = false});

  final int? length;
  final bool fail;

  @override
  Future<int?> contentLength(String url) async {
    if (fail) throw const SocketException('offline');
    return length;
  }
}

class _Installer implements ModelInstaller {
  _Installer({this.failAt});

  bool installed = false;
  final List<int> progress = const [10, 55, 100];
  final int? failAt;
  int installCalls = 0;

  @override
  Future<bool> isInstalled(ModelSpec spec) async => installed;

  @override
  Stream<int> install(ModelSpec spec) async* {
    installCalls++;
    for (final p in progress) {
      if (failAt != null && p >= failAt!) throw const SocketException('lost');
      yield p;
    }
    installed = true;
  }

  @override
  Future<void> activate(ModelSpec spec) async {}
}

void main() {
  test('ModelSpec.fileName 은 URL 마지막 경로', () {
    expect(spec.fileName, 'gemma.litertlm');
    expect(ModelSpec.gemma4E2b.fileName, 'gemma-4-E2B-it.litertlm');
  });

  test('받기 전 크기 확인 -> 진행률(바이트 환산) -> 완료', () async {
    final installer = _Installer();
    final repo = ModelPackRepositoryImpl(spec, _Probe(2000), installer);
    expect(await repo.isInstalled(), isFalse);
    final events = await repo.download(maxBytes: 5000).toList();
    expect(events, [
      const DownloadProgress(received: 0, total: 2000),
      const DownloadProgress(received: 200, total: 2000),
      const DownloadProgress(received: 1100, total: 2000),
      const DownloadProgress(received: 2000, total: 2000),
      const DownloadCompleted(),
    ]);
    expect(await repo.isInstalled(), isTrue);
  });

  test('크기가 상한을 넘으면 받지 않는다 (ModelTooLargeFailure)', () async {
    final installer = _Installer();
    final events = await ModelPackRepositoryImpl(spec, _Probe(6000), installer).download(maxBytes: 5000).toList();
    expect((events.single as DownloadFailed).failure, isA<ModelTooLargeFailure>());
    expect(installer.installCalls, 0);
  });

  test('서버가 크기를 안 알려주면 예상 크기로 상한을 검사한다', () async {
    final events = await ModelPackRepositoryImpl(spec, _Probe(null), _Installer()).download(maxBytes: 999).toList();
    expect(((events.single as DownloadFailed).failure as ModelTooLargeFailure).bytes, 1000);
  });

  test('크기 확인 실패나 받는 중 끊기면 NetworkFailure', () async {
    final offline = await ModelPackRepositoryImpl(spec, _Probe(1, fail: true), _Installer()).download(maxBytes: 5000).toList();
    expect((offline.single as DownloadFailed).failure, isA<NetworkFailure>());
    final lost = await ModelPackRepositoryImpl(spec, _Probe(100), _Installer(failAt: 55)).download(maxBytes: 5000).toList();
    expect((lost.last as DownloadFailed).failure, isA<NetworkFailure>());
  });

  test('설치 확인 중 예외는 미설치로 본다', () async {
    expect(await ModelPackRepositoryImpl(spec, _Probe(1), _ThrowingInstaller()).isInstalled(), isFalse);
  });

  test('DownloadModelPackUseCase 는 상한을 넘기고, percent 는 크기를 모르면 null', () async {
    final events = await DownloadModelPackUseCase(ModelPackRepositoryImpl(spec, _Probe(10), _Installer()), maxBytes: 5)().toList();
    expect((events.single as DownloadFailed).failure, isA<BusinessRuleFailure>());
    expect(const DownloadProgress(received: 5, total: null).percent, isNull);
    expect(const DownloadProgress(received: 5, total: 10).percent, 50);
  });

  group('HttpModelSizeProbe (로컬 HTTP 서버)', () {
    late HttpServer server;
    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((r) {
        if (r.uri.path == '/m.litertlm') {
          r.response
            ..contentLength = 4321
            ..close();
        } else {
          r.response
            ..statusCode = HttpStatus.notFound
            ..close();
        }
      });
    });
    tearDown(() => server.close(force: true));

    test('HEAD 의 Content-Length, 200 이 아니면 HttpException', () async {
      final probe = HttpModelSizeProbe();
      expect(await probe.contentLength('http://127.0.0.1:${server.port}/m.litertlm'), 4321);
      expect(probe.contentLength('http://127.0.0.1:${server.port}/x'), throwsA(isA<HttpException>()));
    });
  });
}

class _ThrowingInstaller extends _Installer {
  @override
  Future<bool> isInstalled(ModelSpec spec) => Future.error(StateError('db'));
}
