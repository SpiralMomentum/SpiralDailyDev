import 'package:flutter/material.dart';

import '../../domain/entities/evaluation.dart';
import 'channel_art.dart';

/// 미연시형 장면 한 컷: 배경, 장소, 평가 칭호, 화자 이름, 대사창.
/// [visibleChars] 만큼만 대사를 보여 줘 타자기 효과와 공유 프레임 캡처를 같은 위젯으로 처리한다.
class VnSceneView extends StatelessWidget {
  const VnSceneView({
    super.key,
    required this.scene,
    required this.line,
    required this.visibleChars,
    required this.titleLabel,
    required this.title,
    this.footer,
  });

  final Scene scene;
  final String line;
  final int visibleChars;
  final String titleLabel;
  final String title;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final shown = line.characters.take(visibleChars).toString();
    final dark = scene.kind == SceneKind.manifestation;
    return Stack(
      fit: StackFit.expand,
      children: [
        ChannelArt(key: ValueKey('art_${scene.art}'), art: scene.art),
        Positioned(
          left: 16,
          right: 16,
          top: 16,
          child: Row(
            children: [
              Flexible(
                child: _Chip(text: scene.place, key: const Key('scene_place')),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _Chip(
                  text: '$titleLabel · $title',
                  key: const Key('scene_title'),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: dark
                      ? const Color(0xFF6C5B7B)
                      : const Color(0xFFB08D57),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
                child: Text(
                  scene.speaker,
                  key: const Key('speaker_name'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                key: const Key('dialogue_box'),
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 110),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.78),
                  border: Border.all(color: Colors.white24),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Text(
                  shown,
                  key: const Key('dialogue_text'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
              ?footer,
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: Colors.white, fontSize: 12),
    ),
  );
}
