import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:utils/utils.dart';

/// 공유 애니메이션의 한 프레임 (RGBA 원본).
final class ShareFrame extends Equatable {
  const ShareFrame({
    required this.rgba,
    required this.width,
    required this.height,
    required this.durationMs,
  });

  final Uint8List rgba;
  final int width;
  final int height;
  final int durationMs;

  @override
  List<Object?> get props => [rgba.length, width, height, durationMs];
}

abstract interface class ShareRepository {
  /// 프레임을 움직이는 이미지(GIF)로 만들어 파일 경로를 돌려준다.
  Future<Result<String>> encode(List<ShareFrame> frames);

  /// 파일을 OS 공유 시트로 넘긴다.
  Future<Result<void>> share(String path, {required String text});
}

class ShareAnimationUseCase {
  const ShareAnimationUseCase(this._repository);

  final ShareRepository _repository;

  Future<Result<String>> call(List<ShareFrame> frames, {required String text}) async {
    if (frames.isEmpty) {
      return const ErrorResult(BusinessRuleFailure(message: 'no frames'));
    }
    final encoded = await _repository.encode(frames);
    if (encoded case Success(:final data)) {
      final shared = await _repository.share(data, text: text);
      return shared.map((_) => data);
    }
    return encoded;
  }
}
