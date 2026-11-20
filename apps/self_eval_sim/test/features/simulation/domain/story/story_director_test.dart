import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_director.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_ledger.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_record.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_world.dart';

import '../../../../support/story_fixtures.dart';

StoryMeeting meet(
  int number,
  String characterId, {
  Relationship relationship = Relationship.friend,
  String? eventId,
  String frameId = 'f_help',
  String outcome = 'O+',
}) => StoryMeeting(
  number: number,
  characterId: characterId,
  relationship: relationship,
  answers: [
    StoryAnswer(
      frameId: frameId,
      variant: const {'who': 'stranger'},
      choiceId: 'c1',
    ),
  ],
  outcome: outcome,
  at: DateTime(2026, 1, number),
  eventId: eventId,
);

List<StoryMeeting> repeat(String id, int times, {int from = 1}) => [
  for (var i = 0; i < times; i++) meet(from + i, id),
];

StoryLedger ledgerOf(List<StoryMeeting> m) => StoryLedger.of(miniWorld, m);

void main() {
  group('StoryDirector', () {
    test('첫 만남은 객잔 주인', () {
      final next = StoryDirector.nextCharacter(
        miniWorld,
        ledgerOf(const []),
        Random(1),
      );
      expect(next.id, 'innkeeper');
    });

    test('만남 2번 뒤 대장장이가 열리고 아직 못 만났으니 먼저 나온다', () {
      final l = ledgerOf(repeat('innkeeper', 2));
      expect(StoryDirector.unlocked(miniWorld, l).map((c) => c.id), [
        'innkeeper',
        'smith',
      ]);
      for (var s = 0; s < 20; s++) {
        expect(
          StoryDirector.nextCharacter(miniWorld, l, Random(s)).id,
          'smith',
        );
      }
    });

    test('은거기인은 만남 4번이어도 객잔 주인 3번 전에는 안 열린다', () {
      final l = ledgerOf([
        meet(1, 'innkeeper'),
        meet(2, 'innkeeper'),
        meet(3, 'smith'),
        meet(4, 'smith'),
      ]);
      expect(l.total, 4);
      expect(
        StoryDirector.unlocked(miniWorld, l).map((c) => c.id),
        isNot(contains('hermit')),
      );
    });

    test('사건 조건을 채운 인물이 먼저 나오고, 사건은 한 번만 일어난다', () {
      final base = [...repeat('innkeeper', 3), meet(4, 'smith')];
      final l = ledgerOf(base);
      expect(
        StoryDirector.pendingEvent(miniWorld, l, 'hermit')?.id,
        'old_friends',
      );
      expect(StoryDirector.nextCharacter(miniWorld, l, Random(3)).id, 'hermit');
      expect(l.links.contains(('innkeeper', 'hermit')), isFalse);

      final after = ledgerOf([
        ...base,
        meet(5, 'hermit', eventId: 'old_friends'),
      ]);
      expect(StoryDirector.pendingEvent(miniWorld, after, 'hermit'), isNull);
      expect(after.firedEvents, {'old_friends'});
      expect(after.links.contains(('innkeeper', 'hermit')), isTrue);
      expect(after.acquainted('hermit', 'innkeeper'), isTrue);
    });

    test('사건 인물이 직전 만남 인물이면 한 만남 미룬다 (다른 열린 인물이 있을 때)', () {
      // 은거기인을 사건 없이 만난 기록: 사건(old_friends)은 아직 남아 있다.
      final base = [
        ...repeat('innkeeper', 3),
        meet(4, 'smith'),
        meet(5, 'hermit'),
      ];
      final l = ledgerOf(base);
      expect(
        StoryDirector.pendingEvent(miniWorld, l, 'hermit')?.id,
        'old_friends',
      );
      for (var s = 0; s < 20; s++) {
        expect(
          StoryDirector.nextCharacter(miniWorld, l, Random(s)).id,
          isNot('hermit'),
          reason: '$s',
        );
      }
      // 한 만남 뒤에는 사건 인물이 나온다.
      final after = ledgerOf([...base, meet(6, 'smith')]);
      expect(
        StoryDirector.nextCharacter(miniWorld, after, Random(1)).id,
        'hermit',
      );
    });

    test('사건 인물 말고 열린 인물이 없으면 연달아라도 사건을 낸다', () {
      final l = ledgerOf([meet(1, 'hermit')]);
      final w = StoryWorld(
        id: miniWorld.id,
        characters: [
          const StoryCharacter(id: 'hermit', theoryId: 'values', unlockAt: 0),
        ],
        theories: miniWorld.theories,
        frames: miniWorld.frames,
        variants: miniWorld.variants,
        events: const [
          StoryEvent(id: 'solo', characterId: 'hermit', met: {'hermit': 1}),
        ],
        links: const [],
      );
      final ledger = StoryLedger.of(w, l.meetings);
      expect(StoryDirector.nextCharacter(w, ledger, Random(1)).id, 'hermit');
    });

    test('직전 인물은 연달아 나오지 않는다 (후보가 둘 이상일 때)', () {
      final l = ledgerOf([
        meet(1, 'innkeeper'),
        meet(2, 'innkeeper'),
        meet(3, 'smith'),
        meet(4, 'smith'),
      ]);
      var repeated = 0;
      final rng = Random(42);
      for (var i = 0; i < 100; i++) {
        if (StoryDirector.nextCharacter(miniWorld, l, rng).id == 'smith') {
          repeated++;
        }
      }
      expect(repeated, 0);
    });

    test('관계는 첫 만남에 정하고 유지한다', () {
      final l = ledgerOf([
        meet(1, 'innkeeper', relationship: Relationship.enemy),
      ]);
      expect(l.relationship('innkeeper'), Relationship.enemy);
      for (var s = 0; s < 20; s++) {
        expect(
          StoryDirector.relationshipFor(l, 'innkeeper', Random(s)),
          Relationship.enemy,
        );
      }
      final seen = {
        for (var s = 0; s < 50; s++)
          StoryDirector.relationshipFor(l, 'smith', Random(s)),
      };
      expect(seen.length, greaterThan(1));
    });

    test('rumorsAbout 은 아는 사이 인물에게 한 답만', () {
      final base = [
        meet(1, 'innkeeper', frameId: 'f_help'),
        meet(2, 'innkeeper', frameId: 'f_trade'),
        meet(3, 'smith', frameId: 'f_lost'),
        meet(4, 'innkeeper', frameId: 'f_help'),
      ];
      final l = ledgerOf(base);
      expect(l.rumorsAbout('smith').map((a) => a.frameId), [
        'f_help',
        'f_trade',
        'f_help',
      ]);
      expect(l.rumorsAbout('hermit'), isEmpty);
      expect(l.answersTo('smith').map((a) => a.frameId), ['f_lost']);
      expect(l.recentFrames(2), ['f_lost', 'f_help']);
      expect(l.lastMetAt('innkeeper'), 4);
      expect(l.metCount('innkeeper'), 3);
      expect(l.lastOutcome('smith'), 'O+');
    });
  });
}
