import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:share_plus/share_plus.dart';
import 'package:utils/utils.dart';

import '../domain/share.dart';

/// 공유 시트 경계. 테스트에서 교체할 수 있게 분리한다.
abstract interface class ShareSink {
  Future<void> shareFile(String path, {required String text});
}

class SharePlusSink implements ShareSink {
  const SharePlusSink();

  @override
  Future<void> shareFile(String path, {required String text}) async {
    await Share.shareXFiles([XFile(path, mimeType: 'image/gif')], text: text);
  }
}

/// 프레임 목록을 GIF 바이트로 만든다. 무거운 작업이라 별도 isolate 에서 돈다.
Uint8List encodeGif(List<ShareFrame> frames) {
  final encoder = img.GifEncoder(repeat: 0, samplingFactor: 20);
  for (final f in frames) {
    final image = img.Image.fromBytes(
      width: f.width,
      height: f.height,
      bytes: f.rgba.buffer,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
    encoder.addFrame(image, duration: (f.durationMs / 10).round());
  }
  return encoder.finish()!;
}

class ShareRepositoryImpl implements ShareRepository {
  ShareRepositoryImpl(this._tempDirectory, this._sink, {this.runInIsolate = true});

  final Future<Directory> Function() _tempDirectory;
  final ShareSink _sink;
  final bool runInIsolate;

  @override
  Future<Result<String>> encode(List<ShareFrame> frames) => guardAsync(
        action: () async {
          final bytes = runInIsolate ? await compute(encodeGif, frames) : encodeGif(frames);
          final dir = await _tempDirectory();
          final file = File('${dir.path}/evaluation_${DateTime.now().millisecondsSinceEpoch}.gif');
          await file.writeAsBytes(bytes, flush: true);
          return file.path;
        },
        onError: (e, st) => LocalStorageFailure(message: 'gif', cause: e, stackTrace: st),
      );

  @override
  Future<Result<void>> share(String path, {required String text}) => guardAsync(
        action: () => _sink.shareFile(path, text: text),
        onError: (e, st) => LocalStorageFailure(message: 'share', cause: e, stackTrace: st),
      );
}
