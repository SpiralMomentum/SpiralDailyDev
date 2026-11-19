import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/accumulation.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/evaluation.dart';
import 'package:self_eval_sim/features/simulation/domain/policies/result_composer.dart';

import '../../../support/fixtures.dart';

void main() {
  final channel = testChannel();
  final text = testText();
  const manifest = ManifestationText(lines: ['m1', 'm2'], separateSpeaker: 'voice', separatePlace: 'void');

  AttemptPlan plan({ManifestationForm? form}) => AttemptPlan(
        channelId: 'wuxia',
        attempt: attempt(5).copyWithArchetype(2),
        manifestation: form == null
            ? null
            : ManifestationRecord(attemptIndex: 5, form: form, materials: [ref(MaterialKind.attempt, 1)]),
      );

  test('발현 없는 결과는 기본 장면 하나 (채널 장소/화자/유형 대사)', () {
    final r = ResultComposer.compose(channel: channel, plan: plan(), text: text);
    expect(r.title, 'wuxia-title2');
    expect(r.manifested, isFalse);
    expect(r.scenes.single.kind, SceneKind.base);
    expect(r.scenes.single.place, 'wuxia-place');
    expect(r.scenes.single.speaker, 'wuxia-speaker');
    expect(r.scenes.single.lines, ['wuxia-reveal wuxia-title2', 'wuxia-a2-l1', 'wuxia-a2-l2', 'wuxia-a2-s2']);
  });

  test('mixed: 기본 장면 대사 뒤에 발현 대사가 섞인다', () {
    final r = ResultComposer.compose(
      channel: channel,
      plan: plan(form: ManifestationForm.mixed),
      text: text,
      manifest: manifest,
    );
    expect(r.manifestationForm, ManifestationForm.mixed);
    expect(r.scenes.single.lines, ['wuxia-reveal wuxia-title2', 'wuxia-a2-l1', 'wuxia-a2-l2', 'wuxia-a2-s2', 'm1', 'm2']);
  });

  test('separate: 기본 장면 뒤에 별도 발현 장면이 붙는다', () {
    final r = ResultComposer.compose(
      channel: channel,
      plan: plan(form: ManifestationForm.separate),
      text: text,
      manifest: manifest,
    );
    expect(r.scenes.map((s) => s.kind), [SceneKind.base, SceneKind.manifestation]);
    expect(r.scenes.last.speaker, 'voice');
    expect(r.scenes.last.place, 'void');
  });

  test('발현 계획이 있어도 문장이 없으면 기본 결과로 내려간다', () {
    final r = ResultComposer.compose(channel: channel, plan: plan(form: ManifestationForm.mixed), text: text);
    expect(r.manifested, isFalse);
    expect(r.scenes, hasLength(1));
  });

  test('광고 보상 확장은 추가 장면(장소)과 추가 서술을 붙이고, 두 번 적용되지 않는다', () {
    final base = ResultComposer.compose(channel: channel, plan: plan(), text: text);
    final once = ResultComposer.extend(base, channel, text);
    final twice = ResultComposer.extend(once, channel, text);
    expect(once.extended, isTrue);
    expect(once.scenes.last.kind, SceneKind.extension);
    expect(once.scenes.last.place, 'wuxia-ext-place');
    expect(once.scenes.last.lines, ['wuxia-ext1', 'wuxia-ext2']);
    expect(twice.scenes, hasLength(2));
  });

  test('재료를 현재 언어 문장으로 풀고, 몇 번 전인지 계산한다', () {
    final m = ResultComposer.resolve(ref(MaterialKind.attempt, 2, q: 'q3', c: 'c2'), 7, text);
    expect(m.ago, 5);
    expect(m.channelName, 'wuxia-name');
    expect(m.choiceText, 'wuxia-q3-c2');
  });
}

extension on AttemptRecord {
  AttemptRecord copyWithArchetype(int archetype) =>
      AttemptRecord(index: index, channelId: channelId, answers: answers, archetype: archetype, at: at);
}
