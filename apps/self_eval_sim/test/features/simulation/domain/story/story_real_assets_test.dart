import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/simulation/data/engine/prompt_builder.dart';
import 'package:self_eval_sim/features/simulation/data/story/story_world_mapper.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/accumulation.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/evaluation.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/text_book.dart';
import 'package:self_eval_sim/features/simulation/domain/story/frame_picker.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_composer.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_judge.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_record.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_text.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_world.dart';

import '../../../../support/story_fixtures.dart';

/// 실제 에셋(무협 세계, 이야기 문장, 기본 문장, 프롬프트)으로 모델 요청과 프롬프트를 만들어
/// 문장 키가 그대로 새거나 빈 칸이 생기지 않는지 본다.
Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

Map<String, String> _strings(String path) =>
    _json(path).map((k, v) => MapEntry(k, v as String));

/// 문장 키 흔적: `theory.` 또는 `story.` 로 시작하는 낱말.
final _key = RegExp(r'(^|[^\w])(theory|story)\.');

void main() {
  final world = StoryWorldMapper.fromJson(
    _json('assets/story/wuxia/world.json'),
  );
  final text = TextBook(
    languageCode: 'ko',
    entries: {
      ..._strings('assets/content/strings/ko.json'),
      ..._strings('assets/story/wuxia/ko.json'),
    },
  );
  final spec = PromptSpec(
    (_json('assets/narration/prompts.json')['languages'] as Map)['ko']
        as Map<String, dynamic>,
  );
  final at = DateTime.utc(2026, 11, 20);

  /// 세계의 모든 틀/선택지에 한 답. 변주는 축마다 첫 값.
  final allAnswers = [
    for (final f in world.frames)
      for (final c in f.choices)
        StoryAnswer(
          frameId: f.id,
          variant: {for (final a in f.axes) a: world.variants[a]!.first},
          choiceId: c.id,
        ),
  ];

  MeetingPlan planFor(
    StoryCharacter character, {
    required JudgmentTone tone,
    required Relationship relationship,
    ManifestationRecord? manifestation,
  }) {
    final theory = world.theoryById(character.theoryId)!;
    final outcome = theoryOutcomes(theory).first;
    final other = world.characters.firstWhere((c) => c.id != character.id);
    return MeetingPlan(
      setup: MeetingSetup(
        character: character,
        relationship: relationship,
        frames: [
          for (final f in world.frames.take(4))
            PickedFrame(
              frame: f,
              variant: {for (final a in f.axes) a: world.variants[a]!.first},
            ),
        ],
        intro: const [],
        number: 5,
      ),
      meeting: StoryMeeting(
        number: 5,
        characterId: character.id,
        relationship: relationship,
        answers: allAnswers,
        outcome: outcome,
        at: at,
      ),
      judgment: Judgment(
        outcome: outcome,
        tone: tone,
        tally: {
          for (final a in theory.axes)
            for (final p in a) p: 1.5,
        },
      ),
      attemptPlan: AttemptPlan(
        channelId: StoryComposer.channelId(world),
        attempt: AttemptRecord(
          index: 5,
          channelId: StoryComposer.channelId(world),
          answers: const [],
          archetype: 0,
          at: at,
          theoryId: theory.id,
        ),
        manifestation: manifestation,
      ),
      pastAnswer: allAnswers.first,
      rumorSourceId: other.id,
      priorAnswerCount: 4,
    );
  }

  test('인물 비유 재료 제한: 말투 밖 자연물 비유는 걸리고, 단어 속 글자와 허용 재료는 통과', () {
    RegExp avoid(String id) => RegExp(text.characterAvoid(world.id, id).single);
    final inn = avoid('innkeeper');
    expect(inn.hasMatch('너는 둑이 튼튼하면 버틴다.'), isTrue);
    expect(inn.hasMatch('맑은 물처럼 흐르는구먼.'), isTrue);
    expect(inn.hasMatch('검을 뽑는 손님'), isTrue);
    expect(inn.hasMatch('물건을 잘 파는구먼.'), isFalse);
    expect(inn.hasMatch('계산이 빠르고 특별한 손님이지.'), isFalse);
    expect(inn.hasMatch('산적을 만나도 술 한 잔이면 풀리지.'), isFalse);
    expect(avoid('ronin').hasMatch('바람이 불면 떠난다.'), isFalse);
    expect(avoid('hermit').hasMatch('허허, 산처럼 앉았구나.'), isFalse);
    expect(avoid('smith').hasMatch('바위 같은 손이다.'), isTrue);
    for (final c in world.characters) {
      expect(text.characterAvoid(world.id, c.id), hasLength(1), reason: c.id);
      expect(text.characterEnding(world.id, c.id), isNotEmpty, reason: c.id);
    }
  });

  test('모든 선택지가 관형형으로 바뀌고, 11명 모두 근거 문장과 묻는 말이 있다', () {
    for (final f in world.frames) {
      for (final c in f.choices) {
        final act = StoryComposer.adnominal(text.frameChoice(world.id, f.id, c.id));
        expect(act, endsWith('는'), reason: '${f.id}.${c.id}');
      }
    }
    for (final c in world.characters) {
      expect(text.characterEvidence(world.id, c.id, '가는'), contains('가는 걸'));
      expect(text.characterAsk(world.id, c.id, 0), isNotEmpty, reason: c.id);
    }
  });

  test('11명 모두, 모든 틀/선택지로 만든 모델 요청에 문장 키가 새지 않는다', () {
    expect(world.characters, hasLength(11));
    for (final c in world.characters) {
      for (final tone in JudgmentTone.values) {
        for (final r in Relationship.values) {
          final req = StoryComposer.baseRequest(
            world,
            text,
            planFor(c, tone: tone, relationship: r),
          );
          for (final (q, choice, trait) in req.answers) {
            for (final s in [q, choice, trait]) {
              expect(_key.hasMatch(s), isFalse, reason: '${c.id}: $s');
            }
          }
          for (final s in [
            ...req.context,
            req.reveal,
            req.title,
            req.speaker,
            req.place,
            ...req.fallbackLines,
          ]) {
            expect(_key.hasMatch(s), isFalse, reason: '${c.id} $tone $r: $s');
          }
        }
      }
    }
  });

  test('발현 요청과 프롬프트에 빈 유형/성향 표, 0개, 문장 키가 없다 (11명)', () {
    final materials = [
      for (final (i, a) in allAnswers.take(3).indexed)
        MaterialRef(
          kind: MaterialKind.attempt,
          sourceIndex: i + 1,
          channelId: StoryComposer.channelId(world),
          questionId: a.frameId,
          choiceId: a.choiceId,
        ),
    ];
    for (final c in world.characters) {
      for (final form in ManifestationForm.values) {
        final req = StoryComposer.manifestationRequest(
          world,
          text,
          planFor(
            c,
            tone: JudgmentTone.confirmed,
            relationship: Relationship.friend,
            manifestation: ManifestationRecord(
              attemptIndex: 5,
              form: form,
              materials: materials,
            ),
          ),
        );
        expect(req.profile, isNotNull, reason: c.id);
        expect(req.profile!.description.trim(), isNotEmpty, reason: c.id);
        expect(req.tally, isNotEmpty, reason: c.id);
        expect(req.totalAnswers, 4 + allAnswers.length, reason: c.id);
        for (final (label, _) in req.tally) {
          expect(_key.hasMatch(label), isFalse, reason: '${c.id}: $label');
        }
        for (final m in req.materials) {
          expect(_key.hasMatch(m.trait), isFalse, reason: '${c.id}: $m');
        }

        final prompt = PromptBuilder.manifestation(spec, req);
        expect(prompt, isNot(contains(' 0개')), reason: c.id);
        expect(prompt, isNot(contains('누적으로 본 상대의 성격: \n')), reason: c.id);
        expect(prompt, isNot(contains('드러난 성향: \n')), reason: c.id);
        expect(_key.hasMatch(prompt), isFalse, reason: '${c.id}: $prompt');
        expect(prompt, isNot(contains('{')), reason: '${c.id}: $prompt');
      }
    }
  });
}
