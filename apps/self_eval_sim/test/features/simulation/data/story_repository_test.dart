import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/simulation/data/story/story_record_mapper.dart';
import 'package:self_eval_sim/features/simulation/data/story/story_repository_impl.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_record.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_world.dart';
import 'package:utils/utils.dart';

StoryMeeting _meeting(int n, {String? eventId}) => StoryMeeting(
  number: n,
  characterId: 'c$n',
  relationship: Relationship.rival,
  answers: const [
    StoryAnswer(frameId: 'f1', variant: {'a': 'x', 'b': 'y'}, choiceId: 'k1'),
  ],
  outcome: '결과 $n',
  at: DateTime.utc(2026, 11, 20, 1, n),
  eventId: eventId,
);

void main() {
  late Directory dir;
  late StoryRepositoryImpl repo;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('story_repo_');
    repo = StoryRepositoryImpl(() async => dir);
  });
  tearDown(() => dir.delete(recursive: true));

  test('만남을 덧붙이고 다시 읽는다', () async {
    expect((await repo.append('w', _meeting(1))).isSuccess, isTrue);
    expect(
      (await repo.append('w', _meeting(2, eventId: 'e1'))).isSuccess,
      isTrue,
    );
    expect((await repo.load('w')).dataOrNull, [
      _meeting(1),
      _meeting(2, eventId: 'e1'),
    ]);
    expect(await File('${dir.path}/story_w.json').exists(), isTrue);
  });

  test('파일이 없으면 빈 목록', () async {
    expect((await repo.load('none')).dataOrNull, isEmpty);
  });

  test('세계마다 파일이 따로다', () async {
    await repo.append('a', _meeting(1));
    expect((await repo.load('b')).dataOrNull, isEmpty);
  });

  test('깨진 이야기 파일은 ParsingFailure', () async {
    await File('${dir.path}/story_w.json').writeAsString('{not json');
    final r = await repo.load('w');
    expect(r.failureOrNull, isA<ParsingFailure>());
    await File(
      '${dir.path}/story_w.json',
    ).writeAsString('{"schema":1,"meetings":[{"n":"x"}]}');
    expect((await repo.load('w')).failureOrNull, isA<ParsingFailure>());
  });

  test('깨진 파일 위에는 덧붙이지 않고 실패한다', () async {
    await File('${dir.path}/story_w.json').writeAsString('{not json');
    expect(
      (await repo.append('w', _meeting(1))).failureOrNull,
      isA<ParsingFailure>(),
    );
  });

  test('clear 는 모든 세계의 이야기 파일만 지운다', () async {
    await repo.append('a', _meeting(1));
    await repo.append('b', _meeting(1));
    final other = File('${dir.path}/accumulation.json')
      ..writeAsStringSync('{}');
    expect((await repo.clear()).isSuccess, isTrue);
    expect((await repo.load('a')).dataOrNull, isEmpty);
    expect((await repo.load('b')).dataOrNull, isEmpty);
    expect(other.existsSync(), isTrue);
  });

  test('clear 는 디렉터리가 없어도 성공', () async {
    final missing = StoryRepositoryImpl(
      () async => Directory('${dir.path}/nope'),
    );
    expect((await missing.clear()).isSuccess, isTrue);
  });

  group('StoryRecordMapper', () {
    test('스키마 1, 시각은 UTC ISO8601, 왕복 동일', () {
      final json = StoryRecordMapper.toJson([_meeting(1)]);
      expect(json['schema'], 1);
      expect(
        ((json['meetings'] as List).first as Map)['at'],
        '2026-11-20T01:01:00.000Z',
      );
      expect(StoryRecordMapper.fromJson(json), [_meeting(1)]);
    });

    test('null 은 빈 목록', () {
      expect(StoryRecordMapper.fromJson(null), isEmpty);
    });
  });
}
