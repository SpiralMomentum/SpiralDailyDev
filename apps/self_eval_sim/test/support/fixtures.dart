import 'dart:math';

import 'package:self_eval_sim/features/simulation/domain/entities/accumulation.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/catalog.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/text_book.dart';
import 'package:self_eval_sim/features/simulation/domain/repositories/accumulation_repository.dart';
import 'package:utils/utils.dart';

/// 문항 3개, 선택지 3개짜리 테스트 채널. q{n}.c{m} 의 유형은 m-1.
Channel testChannel({String id = 'wuxia', int questions = 3}) => Channel(
  id: id,
  art: id,
  archetypeCount: 4,
  questions: [
    for (var q = 1; q <= questions; q++)
      Question(
        id: 'q$q',
        choices: [
          for (var c = 1; c <= 3; c++) Choice(id: 'c$c', archetype: c - 1),
        ],
      ),
  ],
);

/// [testChannel] 하나와 (선택) 성격 이론을 가진 카탈로그. 이론이 없으면 난수를 쓰지 않는다.
ContentCatalog testCatalog({
  Channel? channel,
  List<Theory> theories = const [],
}) => ContentCatalog(
  channels: [channel ?? testChannel()],
  questionsPerAttempt: 2,
  theories: theories,
);

TextBook testText({String languageCode = 'ko'}) {
  final entries = <String, String>{};
  for (final ch in ['wuxia', 'gem']) {
    entries.addAll({
      '$ch.name': '$ch-name',
      '$ch.tagline': '$ch-tagline',
      '$ch.speaker': '$ch-speaker',
      '$ch.place': '$ch-place',
      '$ch.reveal': '$ch-reveal {title}',
      '$ch.style': '$ch-style',
      '$ch.avoid': '금지어',
      '$ch.ext.place': '$ch-ext-place',
      '$ch.ext1': '$ch-ext1',
      '$ch.ext2': '$ch-ext2',
    });
    for (var a = 0; a < 4; a++) {
      entries['$ch.a$a.title'] = '$ch-title$a';
      entries['$ch.a$a.line1'] = '$ch-a$a-l1';
      entries['$ch.a$a.line2'] = '$ch-a$a-l2';
      entries['$ch.a$a.saying1'] = '$ch-a$a-s1';
      entries['$ch.a$a.saying2'] = '$ch-a$a-s2';
      entries['$ch.a$a.saying3'] = '$ch-a$a-s3';
    }
    for (var q = 1; q <= 6; q++) {
      entries['$ch.q$q'] = '$ch-q$q';
      for (var c = 1; c <= 3; c++) {
        entries['$ch.q$q.c$c'] = '$ch-q$q-c$c';
      }
    }
  }
  return TextBook(languageCode: languageCode, entries: entries);
}

AttemptRecord attempt(
  int index, {
  String channelId = 'wuxia',
  List<String>? choices,
}) => AttemptRecord(
  index: index,
  channelId: channelId,
  archetype: 0,
  at: DateTime.utc(2026, 11, 19, 0, index),
  answers: [
    for (var q = 0; q < (choices ?? const ['c1', 'c2']).length; q++)
      Answer(
        questionId: 'q${q + 1}',
        choiceId: (choices ?? const ['c1', 'c2'])[q],
      ),
  ],
);

MaterialRef ref(
  MaterialKind kind,
  int source, {
  String q = 'q1',
  String c = 'c1',
}) => MaterialRef(
  kind: kind,
  sourceIndex: source,
  channelId: 'wuxia',
  questionId: q,
  choiceId: c,
);

/// 도메인 테스트용 메모리 저장소 (Mock 이 아닌 실제 동작하는 대체 구현).
class InMemoryAccumulationRepository implements AccumulationRepository {
  InMemoryAccumulationRepository([this.state = AccumulationState.empty]);

  AccumulationState state;
  bool failSave = false;

  @override
  Future<Result<AccumulationState>> load() async => Success(state);

  @override
  Future<Result<void>> save(AccumulationState next) async {
    if (failSave) {
      return const ErrorResult(LocalStorageFailure(message: 'save'));
    }
    state = next;
    return const Success(null);
  }

  @override
  Future<Result<void>> clear() async {
    state = AccumulationState.empty;
    return const Success(null);
  }
}

/// nextInt 는 [intValue] 를 범위 안으로 잘라 돌려주고, nextBool 은 [bools] 를 순서대로 돌려준다.
class ScriptedRandom implements Random {
  ScriptedRandom({this.intValue = 0, List<bool>? bools})
    : _bools = bools ?? [true];

  final int intValue;
  final List<bool> _bools;
  int _boolIndex = 0;

  @override
  int nextInt(int max) => intValue.clamp(0, max - 1);

  @override
  bool nextBool() => _bools[_boolIndex++ % _bools.length];

  @override
  double nextDouble() => 0;
}
