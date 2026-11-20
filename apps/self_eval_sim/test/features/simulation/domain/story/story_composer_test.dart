import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/accumulation.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/evaluation.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/text_book.dart';
import 'package:self_eval_sim/features/simulation/domain/story/frame_picker.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_composer.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_judge.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_ledger.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_record.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_world.dart';

import '../../../../support/story_fixtures.dart';

void main() {
  const world = miniWorld;
  final text = miniStoryText;
  final innkeeper = world.characterById('innkeeper')!;
  final smith = world.characterById('smith')!;
  final hermit = world.characterById('hermit')!;
  final help = world.frameById('f_help')!;
  final trade = world.frameById('f_trade')!;
  final at = DateTime.utc(2026, 11, 20);

  StoryMeeting meeting(
    int n,
    String characterId, {
    Relationship relationship = Relationship.friend,
    String outcome = 'C+',
    List<StoryAnswer> answers = const [],
  }) => StoryMeeting(
    number: n,
    characterId: characterId,
    relationship: relationship,
    answers: answers,
    outcome: outcome,
    at: at,
  );

  const helpAnswer = StoryAnswer(
    frameId: 'f_help',
    variant: {'who': 'stranger', 'where': 'inn'},
    choiceId: 'c2',
  );

  MeetingSetup setup({
    StoryCharacter? character,
    Relationship relationship = Relationship.friend,
  }) => MeetingSetup(
    character: character ?? innkeeper,
    relationship: relationship,
    frames: [
      PickedFrame(
        frame: help,
        variant: const {'who': 'stranger', 'where': 'inn'},
      ),
      PickedFrame(
        frame: trade,
        variant: const {'who': 'elder'},
        recallChoiceId: 'c2',
      ),
    ],
    intro: const ['도입'],
    number: 1,
  );

  MeetingPlan plan({
    StoryCharacter? character,
    Relationship relationship = Relationship.friend,
    String outcome = 'C+',
    JudgmentTone tone = JudgmentTone.first,
    ManifestationRecord? manifestation,
    StoryAnswer? pastAnswer,
    String? rumorSourceId,
    Map<String, double> tally = const {},
    int priorAnswerCount = 0,
  }) {
    final c = character ?? innkeeper;
    return MeetingPlan(
      setup: setup(character: c, relationship: relationship),
      meeting: meeting(
        1,
        c.id,
        relationship: relationship,
        outcome: outcome,
        answers: const [
          helpAnswer,
          StoryAnswer(
            frameId: 'f_trade',
            variant: {'who': 'elder'},
            choiceId: 'c1',
          ),
        ],
      ),
      judgment: Judgment(outcome: outcome, tone: tone, tally: tally),
      attemptPlan: AttemptPlan(
        channelId: 'story.mini',
        attempt: AttemptRecord(
          index: 3,
          channelId: 'story.mini',
          answers: const [
            Answer(questionId: 'f_help', choiceId: 'c2'),
            Answer(questionId: 'f_trade', choiceId: 'c1'),
          ],
          archetype: 0,
          at: at,
          theoryId: c.theoryId,
        ),
        manifestation: manifestation,
      ),
      pastAnswer: pastAnswer,
      rumorSourceId: rumorSourceId,
      priorAnswerCount: priorAnswerCount,
    );
  }

  test('질문 문장은 변주를 채우고, 재등장이면 연결 문장을 앞에 붙인다', () {
    final qs = StoryComposer.questions(world, text, setup());
    expect(qs, hasLength(2));
    // 변주 축 순서: who(0), where(1). f_help 는 0번 틀, f_trade 는 1번 틀.
    expect(qs[0].id, 'f_help|inn|stranger');
    expect(qs[0].text, '질문 0 변주 0-0 변주 1-0');
    expect(qs[0].choices.map((c) => (c.id, c.text)), [
      ('c1', '선택 0-0'),
      ('c2', '선택 0-1'),
      ('c3', '선택 0-2'),
    ]);
    expect(qs[1].id, 'f_trade|elder');
    expect(qs[1].text, '연결 1-1 질문 1 변주 0-2');
  });

  test('인물이 묻는 한마디가 있으면 줄을 바꿔 따옴표로 붙이고, 문항 순서대로 돌려 쓴다', () {
    final asking = TextBook(
      languageCode: 'ko',
      entries: {
        ...text.entries,
        'story.mini.char.innkeeper.ask.0': '너라면 어쩌겠냐?',
        'story.mini.char.innkeeper.ask.1': '솔직히 말해 봐라.',
      },
    );
    final qs = StoryComposer.questions(world, asking, setup());
    expect(qs[0].text, '질문 0 변주 0-0 변주 1-0\n"너라면 어쩌겠냐?"');
    expect(qs[1].text, '연결 1-1 질문 1 변주 0-2\n"솔직히 말해 봐라."');
  });

  test('adnominal: 현재형 끝을 관형형으로', () {
    expect(StoryComposer.adnominal('해 지기 전에 샛길로 들어간다'), '해 지기 전에 샛길로 들어가는');
    expect(StoryComposer.adnominal('국밥을 먹는다.'), '국밥을 먹는');
    expect(StoryComposer.adnominal('장터에서 판다'), '장터에서 파는');
    expect(StoryComposer.adnominal('이름표를 붙인다'), '이름표를 붙이는');
    expect(StoryComposer.adnominal('조용하다'), '조용하다');
  });

  test('인물 근거 문장이 있으면 결과를 가장 잘 드러낸 답을 짚는 줄이 칭호 다음에 온다', () {
    final evid = TextBook(
      languageCode: 'ko',
      entries: {
        ...text.entries,
        'story.mini.char.innkeeper.evidence.0': '{act} 걸 보니 알겠구먼.',
        'story.mini.char.innkeeper.evidence.1': '{act} 거, 내가 다 봤지.',
        'story.mini.char.innkeeper.avoid': '검|무공',
        'story.mini.char.innkeeper.ending': '(다|지)\$',
      },
    );
    final p = plan();
    final line = StoryComposer.evidenceLine(world, evid, p);
    expect(line, endsWith('걸 보니 알겠구먼.'));
    final r = StoryComposer.result(world: world, text: evid, plan: p);
    expect(r.scenes.single.lines[1], line);
    final req = StoryComposer.baseRequest(world, evid, p);
    expect(req.reveal, endsWith('\n$line'));
    expect(req.echoes, contains(line));
    expect(req.avoid, contains('검|무공'));
    expect(req.ending, '(다|지)\$');
    // 이 인물과 한 번 만난 뒤(답 4개)에는 다음 근거 문장을 쓴다.
    final again = StoryComposer.evidenceLine(
      world,
      evid,
      plan(priorAnswerCount: 4),
    );
    expect(again, endsWith(' 거, 내가 다 봤지.'));
  });

  test('모델 요청은 이야기 프롬프트이고, 칭호 첫 줄과 질문 상황을 되풀이 금지 문장으로 싣는다', () {
    final r = StoryComposer.baseRequest(world, text, plan());
    expect(r.story, isTrue);
    expect(r.echoes, [r.reveal, '질문 0 변주 0-0 변주 1-0', '질문 1 변주 0-2']);
  });

  test('첫 만남에 소문 준 인물이 있으면 rumor 도입, 없으면 first, 다시 만나면 관계별 again', () {
    final empty = StoryLedger.of(world, const []);
    expect(
      StoryComposer.intro(
        world,
        text,
        empty,
        innkeeper,
        Relationship.friend,
        null,
      ),
      ['객잔 주인 첫 만남'],
    );

    // 객잔 주인과 대장장이는 처음부터 아는 사이.
    final metInnkeeper = StoryLedger.of(world, [
      meeting(1, 'innkeeper', answers: const [helpAnswer]),
      meeting(2, 'innkeeper', answers: const [helpAnswer]),
    ]);
    expect(
      StoryComposer.intro(
        world,
        text,
        metInnkeeper,
        smith,
        Relationship.enemy,
        null,
      ),
      ['대장장이 소문 들음 객잔 주인'],
    );
    expect(
      StoryComposer.intro(
        world,
        text,
        metInnkeeper,
        innkeeper,
        Relationship.lover,
        null,
      ),
      // 재회: 관계별 도입 + 지난 답(f_help c2) 연결 문장.
      ['객잔 주인 다시 만남 1', '연결 0-1'],
    );
  });

  test('소문 출처는 아는 인물 중 가장 최근에 만난 인물', () {
    const w = StoryWorld(
      id: 'mini',
      characters: [
        StoryCharacter(id: 'a', theoryId: 'bigfive', unlockAt: 0),
        StoryCharacter(id: 'b', theoryId: 'bigfive', unlockAt: 0),
        StoryCharacter(id: 'c', theoryId: 'bigfive', unlockAt: 0),
      ],
      theories: [],
      frames: [],
      variants: {},
      events: [],
      links: [('a', 'c'), ('b', 'c')],
    );
    final ledger = StoryLedger.of(w, [
      meeting(1, 'b', answers: const [helpAnswer]),
      meeting(2, 'a', answers: const [helpAnswer]),
      meeting(3, 'b', answers: const [helpAnswer]),
    ]);
    expect(StoryComposer.rumorSource(ledger, 'c'), 'b');
    expect(StoryComposer.rumorSource(StoryLedger.of(w, const []), 'c'), isNull);
  });

  test('사건 도입이 맨 앞에 온다', () {
    final ledger = StoryLedger.of(world, [
      for (var i = 1; i <= 4; i++) meeting(i, 'innkeeper'),
    ]);
    final intro = StoryComposer.intro(
      world,
      text,
      ledger,
      hermit,
      Relationship.rival,
      world.events.single,
    );
    expect(intro, ['사건 도입 0', '은거기인 첫 만남']);
  });

  group('결과 장면', () {
    // 화면 어느 줄에도 나오면 안 되는 것: 이론 이름, 결과 코드, 관계 이름과 관계 문장.
    final forbidden = [
      for (final t in world.theories) ...[
        text.of('theory.${t.id}.name'),
        ...theoryOutcomes(t),
      ],
      for (final r in Relationship.values) ...[
        r.name,
        text.of('story.mini.rel.${r.name}.style'),
        text.of('story.mini.ctx.rel.${r.name}'),
      ],
      '친구',
      '연인',
      '악연',
      '라이벌',
    ];

    void expectClean(List<String> lines) {
      for (final line in lines) {
        for (final f in forbidden) {
          expect(line, isNot(contains(f)), reason: '"$line" 에 "$f"');
        }
        expect(line, isNot(startsWith('story.')), reason: '키 누락: $line');
      }
    }

    test('칭호를 밝히는 첫 줄, 모델 대사, 맺음 문장. 이론 이름과 유형 코드는 어느 줄에도 없다', () {
      // bigfive 결과 순서 O+, O-, C+ ... 에서 C+ 는 2번.
      final r = StoryComposer.result(
        world: world,
        text: text,
        plan: plan(relationship: Relationship.lover),
        base: const Narration(
          lines: ['모델 1', '모델 2'],
          source: NarrationSource.model,
        ),
      );
      final scene = r.scenes.single;
      expect(scene.kind, SceneKind.base);
      expect(scene.art, 'innkeeper_art');
      expect(scene.place, '객잔 주인의 자리');
      expect(scene.speaker, '객잔 주인');
      expect(scene.lines, [
        '객잔 주인 왈 너는 객잔 주인 칭호 2',
        '모델 1',
        '모델 2',
        '객잔 주인 맺음 2',
      ]);
      expect(r.channelId, 'story.mini');
      expect(r.archetype, 0);
      expect(r.attemptIndex, 3);
      expect(r.title, '객잔 주인 칭호 2');
      expect(r.baseSource, NarrationSource.model);
      expect(r.manifested, isFalse);
      expectClean(scene.lines);

      // 모델이 없으면 프로필 3줄. 배경 키가 없는 인물은 채널 art.
      final fallback = StoryComposer.result(
        world: world,
        text: text,
        plan: plan(character: smith, outcome: 'I'),
      );
      expect(fallback.scenes.single.art, 'mini');
      expect(fallback.scenes.single.lines, [
        '대장장이 왈 너는 대장장이 칭호 1',
        '유형 1-1 설명',
        '유형 1-1 장점',
        '유형 1-1 약점',
        '대장장이 맺음 1',
      ]);
      expect(fallback.baseSource, NarrationSource.template);
      expectClean(fallback.scenes.single.lines);
    });

    test('발현이면 기존 규칙대로 장면을 섞는다', () {
      final m = ManifestationRecord(
        attemptIndex: 3,
        form: ManifestationForm.separate,
        materials: const [],
      );
      final r = StoryComposer.result(
        world: world,
        text: text,
        plan: plan(manifestation: m),
        manifest: const ManifestationText(
          lines: ['발현'],
          separateSpeaker: '목소리',
          separatePlace: '어딘가',
        ),
      );
      expect(r.scenes, hasLength(2));
      expect(r.scenes.last.lines, ['발현']);
      expect(r.manifestationForm, ManifestationForm.separate);
    });
  });

  test('모델 요청에 관계/판단 흐름/지난 근거/소문 context 가 실리고 style 은 세계+인물+관계 순', () {
    final r = StoryComposer.baseRequest(
      world,
      text,
      plan(
        relationship: Relationship.rival,
        tone: JudgmentTone.surprised,
        pastAnswer: helpAnswer,
        rumorSourceId: 'smith',
      ),
    );
    expect(r.context, ['관계 문장 3', '흐름 문장 2', '지난번 근거 선택 0-1', '소문 출처 대장장이']);
    expect(r.style, '세계 말투\n객잔 주인 말투\n관계 말투 3');
    expect(r.avoid, ['그녀|소저']);
    expect(r.examples, isEmpty);
    expect(r.speaker, '객잔 주인');
    expect(r.place, '객잔 주인의 자리');
    expect(r.title, '객잔 주인 칭호 2');
    expect(r.reveal, '의외 접두 객잔 주인 왈 너는 객잔 주인 칭호 2');
    expect(r.answers.first, ('질문 0 변주 0-0 변주 1-0', '선택 0-1', '성향 0-2'));
    expect(r.answers.last, ('질문 1 변주 0-2', '선택 1-0', '성향 0-6'));
    expect(r.profile!.description, '유형 0-2 설명');
    expect(r.fallbackLines, ['유형 0-2 설명', '유형 0-2 장점', '유형 0-2 약점']);

    // 첫 만남이고 소문이 없으면 관계와 흐름 두 줄만.
    final first = StoryComposer.baseRequest(world, text, plan());
    expect(first.context, ['관계 문장 0', '흐름 문장 0']);
  });

  test('발현 요청: 인물 이름과 칭호, 이야기 재료는 세계 이름과 선택지 문장으로 풀린다', () {
    const story = MaterialRef(
      kind: MaterialKind.attempt,
      sourceIndex: 1,
      channelId: 'story.mini',
      questionId: 'f_help',
      choiceId: 'c1',
    );
    ManifestationRequest request(ManifestationForm form) =>
        StoryComposer.manifestationRequest(
          world,
          text,
          plan(
            manifestation: ManifestationRecord(
              attemptIndex: 3,
              form: form,
              materials: const [story],
            ),
          ),
        );
    final mixed = request(ManifestationForm.mixed);
    expect(mixed.speaker, '객잔 주인');
    expect(mixed.title, '객잔 주인 칭호 2');
    expect(
      mixed.materials.single,
      const ResolvedMaterial(
        kind: MaterialKind.attempt,
        ago: 2,
        channelName: '작은 강호',
        choiceText: '선택 0-0',
        // f_help c1 = O+ (bigfive 0번 극)
        trait: '성향 0-0',
      ),
    );
    expect(mixed.today, ['선택 0-1', '선택 1-0']);
    expect(mixed.style, '세계 말투\n객잔 주인 말투');
    expect(mixed.avoid, ['그녀|소저']);
    expect(request(ManifestationForm.separate).style, isEmpty);
  });

  test('발현 요청: 인물 이론 기준 유형, 성향 표, 이 인물에게 한 답 수(이번 포함)가 채워진다', () {
    final r = StoryComposer.manifestationRequest(
      world,
      text,
      plan(
        tally: const {'C+': 3, 'A+': 1, 'O+': 0.5},
        priorAnswerCount: 6,
        manifestation: ManifestationRecord(
          attemptIndex: 3,
          form: ManifestationForm.separate,
          materials: const [
            // 이야기 밖 채널 재료는 이 인물 이론으로 읽을 수 없어 성향을 비운다.
            MaterialRef(
              kind: MaterialKind.attempt,
              sourceIndex: 2,
              channelId: 'wuxia',
              questionId: 'q1',
              choiceId: 'a',
            ),
          ],
        ),
      ),
    );
    expect(r.profile, isNotNull);
    expect(r.profile!.description, '유형 0-2 설명');
    // 많은 순, 소문 반 표는 반올림 (0.5 -> 1).
    expect(r.tally, [('성향 0-2', 3), ('성향 0-6', 1), ('성향 0-0', 1)]);
    expect(r.totalAnswers, 8);
    expect(r.materials.single.trait, isEmpty);
  });

  group('기억이 화면에 드러난다', () {
    // 지난 만남: f_help(c2, C+), f_trade(c1, A+). 지난 판단 C+.
    const tradeAnswer = StoryAnswer(
      frameId: 'f_trade',
      variant: {'who': 'elder'},
      choiceId: 'c1',
    );
    final ledger = StoryLedger.of(world, [
      meeting(1, 'innkeeper', answers: const [tradeAnswer, helpAnswer]),
    ]);

    test('다시 만나면 관계별 도입 뒤에 지난 만남 답 하나의 연결 문장 (판단을 드러낸 답 우선)', () {
      final intro = StoryComposer.intro(
        world,
        text,
        ledger,
        innkeeper,
        Relationship.lover,
        null,
      );
      // f_help 는 0번 틀, c2 는 1번 선택지. C+ 를 드러낸 답이라 앞선다.
      expect(intro, ['객잔 주인 다시 만남 1', '연결 0-1']);
      expect(intro.last, isNot(contains('{')));
    });

    test('이번 질문에 다시 나오는 틀(질문에 연결 문장이 붙음)은 도입에서 짚지 않는다', () {
      final intro = StoryComposer.intro(
        world,
        text,
        ledger,
        innkeeper,
        Relationship.lover,
        null,
        asked: const {'f_help'},
      );
      expect(intro, ['객잔 주인 다시 만남 1', '연결 1-0']);
      final none = StoryComposer.intro(
        world,
        text,
        ledger,
        innkeeper,
        Relationship.lover,
        null,
        asked: const {'f_help', 'f_trade'},
      );
      expect(none, ['객잔 주인 다시 만남 1']);
    });

    test('다시 만난 결과의 첫 줄에 tone 별 접두: 인물 문장이 있으면 인물, 없으면 세계 공통', () {
      List<String> lines(StoryCharacter c, JudgmentTone tone) =>
          StoryComposer.result(
            world: world,
            text: text,
            plan: plan(character: c, outcome: 'I', tone: tone),
          ).scenes.single.lines;
      // 객잔 주인(0번 인물)만 인물별 접두가 있다.
      expect(
        StoryComposer.result(
          world: world,
          text: text,
          plan: plan(tone: JudgmentTone.confirmed),
        ).scenes.single.lines.first,
        '객잔 주인 역시 객잔 주인 왈 너는 객잔 주인 칭호 2',
      );
      expect(
        lines(smith, JudgmentTone.confirmed).first,
        '역시 접두 대장장이 왈 너는 대장장이 칭호 1',
      );
      expect(
        lines(smith, JudgmentTone.surprised).first,
        '의외 접두 대장장이 왈 너는 대장장이 칭호 1',
      );
      expect(lines(smith, JudgmentTone.first).first, '대장장이 왈 너는 대장장이 칭호 1');
      expect(lines(smith, JudgmentTone.neutral).first, '대장장이 왈 너는 대장장이 칭호 1');
      // 모델에 주는 첫 대사도 화면 첫 줄과 같다.
      expect(
        StoryComposer.baseRequest(
          world,
          text,
          plan(character: smith, outcome: 'I', tone: JudgmentTone.surprised),
        ).reveal,
        '의외 접두 대장장이 왈 너는 대장장이 칭호 1',
      );
    });
  });
}
