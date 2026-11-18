import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/simulation/presentation/widgets/channel_art.dart';

import '../../../support/pump.dart';

void main() {
  testWidgets('에셋이 있는 장면은 이미지, 없는 장면은 코드 배경', (tester) async {
    await tester.pumpLocalized(const ChannelArt(art: 'wuxia'));
    expect(find.byType(Image), findsOneWidget);
    await tester.pumpLocalized(const ChannelArt(art: 'unknown_scene'));
    expect(find.byType(Image), findsNothing);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('코드 배경은 모든 채널/확장/발현 키를 예외 없이 그린다', (tester) async {
    for (final art in [...ChannelArt.assetKeys, 'unknown']) {
      await tester.pumpLocalized(ChannelArt(art: art, paintedOnly: true));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: art);
      expect(find.byType(Image), findsNothing);
    }
  });

  test('에셋 키와 경로, 팔레트', () {
    expect(ChannelArt.assetPath('gem_ext'), 'assets/images/scenes/gem_ext.jpg');
    expect(ChannelArt.imageOf('nope'), isNull);
    expect(ChannelArt.paletteOf('gem_ext'), ChannelArt.palettes['gem']);
    expect(ChannelArt.paletteOf('nope'), ChannelArt.palettes['manifestation']);
  });
}
