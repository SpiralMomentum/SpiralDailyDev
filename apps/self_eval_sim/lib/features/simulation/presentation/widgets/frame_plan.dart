import '../../domain/entities/evaluation.dart';

/// 공유 애니메이션 프레임 하나의 화면 상태.
typedef FrameSpec = ({int scene, int line, int visibleChars, int durationMs});

/// 결과 장면을 미연시 대사창이 흘러가는 프레임 목록으로 바꾼다 (순수 함수).
/// 줄마다 타자 프레임 [typingSteps] 장 + 멈춤 프레임 1장. 전체 줄은 [maxLines] 까지.
abstract final class FramePlan {
  static const typingSteps = 6;
  static const typingMs = 80;
  static const holdMs = 1400;
  static const maxLines = 6;

  static List<FrameSpec> build(List<Scene> scenes) {
    final lines = [
      for (var s = 0; s < scenes.length; s++)
        for (var l = 0; l < scenes[s].lines.length; l++)
          (scene: s, line: l, length: scenes[s].lines[l].characters.length),
    ].take(maxLines);
    return [
      for (final x in lines) ...[
        for (var step = 1; step < typingSteps; step++)
          (
            scene: x.scene,
            line: x.line,
            visibleChars: (x.length * step / typingSteps).ceil(),
            durationMs: typingMs,
          ),
        (scene: x.scene, line: x.line, visibleChars: x.length, durationMs: holdMs),
      ],
    ];
  }
}

extension on String {
  Iterable<String> get characters => runes.map(String.fromCharCode);
}
