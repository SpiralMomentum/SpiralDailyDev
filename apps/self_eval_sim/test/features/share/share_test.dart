import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:self_eval_sim/features/share/data/share_impl.dart';
import 'package:self_eval_sim/features/share/domain/share.dart';
import 'package:utils/utils.dart';

class _RecordingSink implements ShareSink {
  final shared = <(String, String)>[];
  bool fail = false;

  @override
  Future<void> shareFile(String path, {required String text}) async {
    if (fail) throw StateError('cancelled');
    shared.add((path, text));
  }
}

ShareFrame frame(int r, {int ms = 100}) => ShareFrame(
      rgba: Uint8List.fromList([for (var i = 0; i < 8 * 6; i++) ...[r, 0, 0, 255]]),
      width: 8,
      height: 6,
      durationMs: ms,
    );

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('share'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('encodeGif: 프레임 수와 크기가 유지되는 GIF89a 애니메이션', () {
    final bytes = encodeGif([frame(255, ms: 80), frame(0, ms: 1400)]);
    expect(String.fromCharCodes(bytes.sublist(0, 6)), 'GIF89a');
    final decoded = img.decodeGif(bytes)!;
    expect(decoded.numFrames, 2);
    expect(decoded.width, 8);
    expect(decoded.height, 6);
  });

  test('ShareAnimationUseCase: GIF 파일을 만들어 공유 시트로 넘긴다', () async {
    final sink = _RecordingSink();
    final useCase = ShareAnimationUseCase(ShareRepositoryImpl(() async => dir, sink, runInIsolate: false));
    final result = await useCase([frame(10), frame(20)], text: 'caption');
    final path = result.dataOrNull!;
    expect(path, endsWith('.gif'));
    expect(File(path).existsSync(), isTrue);
    expect(sink.shared.single, (path, 'caption'));
  });

  test('프레임이 없으면 BusinessRuleFailure', () async {
    final useCase = ShareAnimationUseCase(ShareRepositoryImpl(() async => dir, _RecordingSink(), runInIsolate: false));
    expect((await useCase(const [], text: 'x')).failureOrNull, isA<BusinessRuleFailure>());
  });

  test('공유 실패는 Failure', () async {
    final sink = _RecordingSink()..fail = true;
    final useCase = ShareAnimationUseCase(ShareRepositoryImpl(() async => dir, sink, runInIsolate: false));
    expect((await useCase([frame(1)], text: 'x')).isError, isTrue);
  });
}
