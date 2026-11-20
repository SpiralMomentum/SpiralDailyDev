import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/accumulation.dart';
import 'package:self_eval_sim/features/simulation/domain/policies/archetype_resolver.dart';
import 'package:self_eval_sim/features/simulation/domain/policies/question_sampler.dart';

import '../../../support/fixtures.dart';

void main() {
  final channel = testChannel(questions: 6);
  Answer a(String q, String c) => Answer(questionId: q, choiceId: c);

  group('ArchetypeResolver', () {
    test('가장 많이 고른 유형을 고른다', () {
      expect(ArchetypeResolver.resolve(channel, [a('q1', 'c2'), a('q2', 'c2'), a('q3', 'c1')]), 1);
    });

    test('동률이면 동률 중 마지막에 고른 유형', () {
      expect(ArchetypeResolver.resolve(channel, [a('q1', 'c1'), a('q2', 'c3'), a('q3', 'c1'), a('q4', 'c3')]), 2);
    });

    test('알 수 없는 문항/선택은 무시하고, 남는 게 없으면 0', () {
      expect(ArchetypeResolver.resolve(channel, [a('zz', 'c1'), a('q1', 'zz')]), 0);
    });
  });

  group('QuestionSampler', () {
    test('요청 수만큼 중복 없이 원래 순서대로 고른다', () {
      final picked = QuestionSampler.sample(channel, 4, Random(9));
      expect(picked, hasLength(4));
      expect(picked.toSet(), hasLength(4));
      final order = picked.map((q) => channel.questions.indexOf(q)).toList();
      expect(order, List.of(order)..sort());
    });

    test('문항이 부족하면 있는 만큼', () {
      expect(QuestionSampler.sample(testChannel(questions: 2), 4, Random(1)), hasLength(2));
    });
  });
}
