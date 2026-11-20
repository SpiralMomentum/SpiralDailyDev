import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/simulation/data/mappers/catalog_mapper.dart';
import 'package:self_eval_sim/features/simulation/data/story/story_world_mapper.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_record.dart';

import '../../../support/story_fixtures.dart';

void main() {
  test('world.json 형식을 읽는다', () {
    expect(StoryWorldMapper.fromJson(miniWorldJson), miniWorld);
  });

  test('measures/poleAlias/outcomeAlias 를 읽고 tagSource 는 measures', () {
    final type16 = StoryWorldMapper.fromJson(
      miniWorldJson,
    ).theoryById('type16')!;
    expect(type16.tagSource, 'bigfive');
    expect(type16.poleAlias['E-'], 'I');
    expect(type16.outcomeAlias, isEmpty);
    expect(miniWorld.theoryById('bigfive')!.tagSource, 'bigfive');

    final temperament = CatalogMapper.theory({
      'id': 'temperament',
      'mode': 'code',
      'axes': [
        ['E+', 'E-'],
        ['N+', 'N-'],
      ],
      'measures': 'bigfive',
      'outcomeAlias': {'E+N-': 'sanguine', 'E-N-': 'phlegmatic'},
    });
    expect(temperament.outcomeAlias['E+N-'], 'sanguine');
  });

  test('기존 structure.json 이론은 그대로 읽힌다', () {
    final json =
        jsonDecode(File('assets/content/structure.json').readAsStringSync())
            as Map<String, dynamic>;
    final theories = CatalogMapper.catalog(json).theories;
    expect(theories, hasLength(4));
    expect(theories.every((t) => t.measures == null), isTrue);
    expect(theories.every((t) => t.tagSource == t.id), isTrue);
  });

  test('조회 함수와 comboKey', () {
    expect(miniWorld.characterById('smith')!.theoryId, 'holland');
    expect(miniWorld.frameById('f_help'), isNotNull);
    expect(miniWorld.frameById('nope'), isNull);
    const answer = StoryAnswer(
      frameId: 'f_help',
      variant: {'where': 'inn', 'who': 'friend'},
      choiceId: 'c1',
    );
    expect(answer.comboKey, 'f_help|inn|friend');
  });
}
