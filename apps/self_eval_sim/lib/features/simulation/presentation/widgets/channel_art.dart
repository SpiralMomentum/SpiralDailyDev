import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 채널 장면 배경. `assets/images/scenes/<art>.jpg` (AI 도구로 사전 제작한 샘플 에셋)를 쓰고,
/// 에셋이 없거나 읽지 못하면 코드로 그린 배경으로 대체한다.
class ChannelArt extends StatelessWidget {
  const ChannelArt({super.key, required this.art, this.paintedOnly = false});

  final String art;

  /// 에셋을 쓰지 않고 코드 배경만 그린다 (에셋 미제공 채널, 테스트).
  final bool paintedOnly;

  /// 에셋이 있는 장면 키. 에셋을 추가하면 여기에도 추가한다.
  static const assetKeys = {
    'wuxia', 'wuxia_ext', 'fantasy', 'fantasy_ext', 'animal', 'animal_ext',
    'gem', 'gem_ext', 'manifestation',
  };

  static String assetPath(String art) => 'assets/images/scenes/$art.jpg';

  static ImageProvider? imageOf(String art) =>
      assetKeys.contains(art) ? AssetImage(assetPath(art)) : null;

  static const palettes = <String, List<Color>>{
    'wuxia': [Color(0xFF2E3A46), Color(0xFF8A9BA8), Color(0xFFD9DED8)],
    'fantasy': [Color(0xFF3B2259), Color(0xFF9B5DE5), Color(0xFFF7C8E0)],
    'animal': [Color(0xFF0F2A1D), Color(0xFF2D6A4F), Color(0xFFB7E4C7)],
    'gem': [Color(0xFF1B1B2F), Color(0xFF7A1F3D), Color(0xFFE9C46A)],
    'manifestation': [Color(0xFF050505), Color(0xFF1F1A2E), Color(0xFF6C5B7B)],
  };

  static List<Color> paletteOf(String art) =>
      palettes[art.replaceAll('_ext', '')] ?? palettes['manifestation']!;

  @override
  Widget build(BuildContext context) {
    final image = paintedOnly ? null : imageOf(art);
    if (image == null) return _painted();
    return Image(
      image: image,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => _painted(),
    );
  }

  Widget _painted() {
    final colors = paletteOf(art);
    final extended = art.endsWith('_ext');
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: extended ? colors.reversed.toList() : colors,
        ),
      ),
      child: CustomPaint(
        painter: _ScenePainter(art.replaceAll('_ext', ''), colors, extended),
        size: Size.infinite,
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.kind, this.colors, this.extended);

  final String kind;
  final List<Color> colors;
  final bool extended;

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case 'wuxia':
        _mountains(canvas, size);
      case 'fantasy':
        _palace(canvas, size);
      case 'animal':
        _forest(canvas, size);
      case 'gem':
        _gem(canvas, size);
      default:
        _void(canvas, size);
    }
  }

  void _mountains(Canvas canvas, Size s) {
    final far = Paint()..color = colors[0].withValues(alpha: 0.55);
    final near = Paint()..color = colors[0];
    canvas.drawPath(
      Path()
        ..moveTo(0, s.height * 0.55)
        ..lineTo(s.width * 0.25, s.height * 0.3)
        ..lineTo(s.width * 0.45, s.height * 0.5)
        ..lineTo(s.width * 0.7, s.height * 0.22)
        ..lineTo(s.width, s.height * 0.48)
        ..lineTo(s.width, s.height)
        ..lineTo(0, s.height)
        ..close(),
      far,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, s.height * 0.7)
        ..lineTo(s.width * 0.35, s.height * 0.5)
        ..lineTo(s.width * 0.6, s.height * 0.66)
        ..lineTo(s.width, s.height * 0.55)
        ..lineTo(s.width, s.height)
        ..lineTo(0, s.height)
        ..close(),
      near,
    );
    final mist = Paint()..color = Colors.white.withValues(alpha: 0.18);
    for (var i = 0; i < 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(s.width * (0.2 + i * 0.3), s.height * (0.58 + i * 0.04)),
          width: s.width * 0.7,
          height: s.height * 0.06,
        ),
        mist,
      );
    }
  }

  void _palace(Canvas canvas, Size s) {
    final p = Paint()..color = colors[0].withValues(alpha: 0.85);
    final base = s.height * 0.72;
    for (var i = 0; i < 5; i++) {
      final x = s.width * (0.1 + i * 0.2);
      final h = s.height * (i.isEven ? 0.38 : 0.3);
      canvas.drawRect(Rect.fromLTWH(x - 14, base - h, 28, h), p);
      canvas.drawPath(
        Path()
          ..moveTo(x - 22, base - h)
          ..lineTo(x, base - h - 40)
          ..lineTo(x + 22, base - h)
          ..close(),
        p,
      );
    }
    canvas.drawRect(Rect.fromLTWH(0, base, s.width, s.height - base), p);
    final star = Paint()..color = Colors.white.withValues(alpha: 0.7);
    final rnd = math.Random(7);
    for (var i = 0; i < 30; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height * 0.35),
        rnd.nextDouble() * 1.6 + 0.4,
        star,
      );
    }
  }

  void _forest(Canvas canvas, Size s) {
    canvas.drawCircle(
      Offset(s.width * 0.75, s.height * 0.16),
      s.width * 0.1,
      Paint()..color = const Color(0xFFFFF3C4),
    );
    final tree = Paint()..color = colors[0];
    for (var i = 0; i < 7; i++) {
      final x = s.width * i / 6;
      final h = s.height * (0.35 + (i % 3) * 0.08);
      canvas.drawPath(
        Path()
          ..moveTo(x - 34, s.height * 0.75)
          ..lineTo(x, s.height * 0.75 - h)
          ..lineTo(x + 34, s.height * 0.75)
          ..close(),
        tree,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(0, s.height * 0.74, s.width, s.height * 0.26),
      tree,
    );
  }

  void _gem(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height * 0.36);
    final r = s.width * 0.22;
    final facets = [
      Paint()..color = colors[1],
      Paint()..color = colors[2].withValues(alpha: 0.85),
      Paint()..color = colors[1].withValues(alpha: 0.6),
    ];
    for (var i = 0; i < 8; i++) {
      final a1 = i * math.pi / 4;
      final a2 = (i + 1) * math.pi / 4;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy)
          ..lineTo(c.dx + r * math.cos(a1), c.dy + r * math.sin(a1))
          ..lineTo(c.dx + r * math.cos(a2), c.dy + r * math.sin(a2))
          ..close(),
        facets[i % 3],
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(0, s.height * 0.68, s.width, s.height * 0.32),
      Paint()..color = const Color(0xFF3D2B1F),
    );
  }

  void _void(Canvas canvas, Size s) {
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = colors[2].withValues(alpha: 0.5);
    for (var i = 1; i < 9; i++) {
      canvas.drawCircle(Offset(s.width / 2, s.height * 0.35), i * s.width * 0.07, ring);
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) =>
      old.kind != kind || old.extended != extended;
}
