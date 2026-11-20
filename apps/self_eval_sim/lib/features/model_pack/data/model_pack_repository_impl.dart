import 'package:utils/utils.dart';

import '../domain/model_pack.dart';
import 'model_installer.dart';

/// 모델 하나를 받아 설치한다. 받기 전에 크기를 확인해 용량 상한을 넘으면 받지 않는다.
class ModelPackRepositoryImpl implements ModelPackRepository {
  const ModelPackRepositoryImpl(this._spec, this._probe, this._installer);

  final ModelSpec _spec;
  final ModelSizeProbe _probe;
  final ModelInstaller _installer;

  @override
  Future<bool> isInstalled() async {
    try {
      return await _installer.isInstalled(_spec);
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<DownloadEvent> download({required int maxBytes}) async* {
    try {
      final total = await _probe.contentLength(_spec.url) ?? _spec.expectedBytes;
      if (ModelPackPolicy.exceeds(total, maxBytes)) {
        yield DownloadFailed(ModelTooLargeFailure(bytes: total, limit: maxBytes));
        return;
      }
      yield DownloadProgress(received: 0, total: total);
      await for (final percent in _installer.install(_spec)) {
        yield DownloadProgress(received: total * percent ~/ 100, total: total);
      }
      yield const DownloadCompleted();
    } catch (e, st) {
      yield DownloadFailed(NetworkFailure(message: 'model', cause: e, stackTrace: st));
    }
  }
}
