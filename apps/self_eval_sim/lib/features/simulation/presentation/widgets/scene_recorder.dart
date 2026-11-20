import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../domain/entities/evaluation.dart';
import 'channel_art.dart';
import 'frame_plan.dart';
import 'vn_scene_view.dart';

/// 캡처된 프레임 (RGBA 원본). 공유 기능과는 앱 조립 영역에서 이어 붙인다.
typedef CapturedFrame = ({Uint8List rgba, int width, int height, int durationMs});

/// 결과 장면을 고정 크기로 그리면서 프레임 계획대로 한 장씩 캡처한다.
/// 다이얼로그 안에 축소해 보여 주며, 끝나면 프레임 목록으로 pop 한다.
class SceneRecorder extends StatefulWidget {
  const SceneRecorder({
    super.key,
    required this.result,
    required this.titleLabel,
    required this.message,
  });

  static const logicalSize = Size(320, 568);
  static const pixelRatio = 0.75;

  final EvaluationResult result;
  final String titleLabel;
  final String message;

  static Future<List<CapturedFrame>?> record(
    BuildContext context, {
    required EvaluationResult result,
    required String titleLabel,
    required String message,
  }) =>
      showDialog<List<CapturedFrame>>(
        context: context,
        barrierDismissible: false,
        builder: (_) => SceneRecorder(
          result: result,
          titleLabel: titleLabel,
          message: message,
        ),
      );

  @override
  State<SceneRecorder> createState() => _SceneRecorderState();
}

class _SceneRecorderState extends State<SceneRecorder> {
  final _boundary = GlobalKey();
  late final List<FrameSpec> _plan = FramePlan.build(widget.result.scenes);
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    for (final scene in widget.result.scenes) {
      final image = ChannelArt.imageOf(scene.art);
      if (image != null && mounted) await precacheImage(image, context, onError: (_, _) {});
    }
    final frames = <CapturedFrame>[];
    for (var i = 0; i < _plan.length; i++) {
      if (!mounted) return;
      setState(() => _index = i);
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: SceneRecorder.pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      frames.add((
        rgba: data!.buffer.asUint8List(),
        width: image.width,
        height: image.height,
        durationMs: _plan[i].durationMs,
      ));
      image.dispose();
    }
    if (mounted) Navigator.of(context).pop(frames);
  }

  @override
  Widget build(BuildContext context) {
    final spec = _plan[_index];
    final scene = widget.result.scenes[spec.scene];
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.message, key: const Key('share_making')),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: (_index + 1) / _plan.length),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: FittedBox(
                child: RepaintBoundary(
                  key: _boundary,
                  child: SizedBox.fromSize(
                    size: SceneRecorder.logicalSize,
                    child: MediaQuery(
                      data: const MediaQueryData(size: SceneRecorder.logicalSize),
                      child: VnSceneView(
                        scene: scene,
                        line: scene.lines[spec.line],
                        visibleChars: spec.visibleChars,
                        titleLabel: widget.titleLabel,
                        title: widget.result.title,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
