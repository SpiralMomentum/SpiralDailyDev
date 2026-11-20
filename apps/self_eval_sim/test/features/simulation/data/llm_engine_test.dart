import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/simulation/data/engine/fallback_narration_engine.dart';
import 'package:self_eval_sim/features/simulation/data/engine/line_sanitizer.dart';
import 'package:self_eval_sim/features/simulation/data/engine/llm_client.dart';
import 'package:self_eval_sim/features/simulation/data/engine/llm_narration_engine.dart';
import 'package:self_eval_sim/features/simulation/data/engine/template_narration_engine.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/accumulation.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/evaluation.dart';
import 'package:utils/utils.dart';

/// 정해진 응답을 돌려주고 받은 프롬프트/시드를 기록하는 LLM 대체 구현 (DataSource 대체).
class _ScriptedLlm implements LlmClient {
  _ScriptedLlm(this.responses);

  final List<Object> responses;
  final prompts = <String>[];
  final seeds = <int>[];

  @override
  Future<String> generate(String prompt, {required int seed}) async {
    prompts.add(prompt);
    seeds.add(seed);
    final next = responses.removeAt(0);
    if (next is Exception) throw next;
    return next as String;
  }
}

void main() {
  final promptsJson = File('assets/narration/prompts.json').readAsStringSync();
  final templatesJson = File(
    'assets/narration/templates.json',
  ).readAsStringSync();

  const base = BaseNarrationRequest(
    languageCode: 'ko',
    speaker: '보석상 주인',
    place: '골목 끝 작은 보석상',
    title: '깊은 바다의 사파이어',
    answers: [('곤란한 부탁을 받았다.', '하루 생각해 보고 답한다', '신중')],
    examples: ['빛을 바로 내주지 않는 돌입니다.'],
    fallbackLines: ['콘텐츠 1', '콘텐츠 2'],
    reveal: '당신은 깊은 바다의 사파이어처럼 보이네요.',
    style: '감정 어휘는 하나만 쓴다.',
    avoid: ['(?i)석탄'],
    profile: TypeProfile(
      theoryName: '에니어그램',
      label: '6번 · 대비하는 사람',
      description: '무엇이 잘못될지 먼저 따져 보는 사람이다',
      strength: '믿고 맡길 수 있다',
      weakness: '의심이 결정을 늦춘다',
    ),
  );
  const manifest = ManifestationRequest(
    languageCode: 'ko',
    form: ManifestationForm.separate,
    speaker: '보석상 주인',
    title: '깊은 바다의 사파이어',
    materials: [
      ResolvedMaterial(
        kind: MaterialKind.attempt,
        ago: 2,
        channelName: '무협',
        choiceText: '검을 뽑는다',
      ),
      ResolvedMaterial(
        kind: MaterialKind.manifestation,
        ago: 5,
        channelName: '보석',
        choiceText: '사진',
      ),
    ],
  );

  group('LineSanitizer', () {
    List<String> clean(String raw, {int maxLines = 3}) => LineSanitizer.clean(
      raw,
      title: '사파이어',
      maxLength: 20,
      maxLines: maxLines,
      banned: [RegExp('당신은.*사람')],
    );

    test('번호, 글머리표, 이름표, 감싼 따옴표, 특수 토큰, 빈 줄을 걷어낸다', () {
      expect(
        clean('<|channel>1. "첫 줄이다."\n\n- 보석상 주인: 둘째 줄.\n「셋째」<end_of_turn>'),
        ['첫 줄이다.', '둘째 줄.', '셋째'],
      );
    });

    test('결과 이름이 든 줄, 금지 패턴, 길이 1.5배 초과, 중복은 버리고 maxLines 까지만', () {
      expect(
        clean(
          '깊은 바다의 사파이어군요.\n당신은 차분한 사람입니다.\n${'가' * 31}\n좋다.\n좋다.\n하나.\n둘.\n셋.',
        ),
        ['좋다.', '하나.', '둘.'],
      );
    });

    test('overlaps: 공백과 문장부호를 빼고 정한 글자 수 이상 이어서 겹치는지', () {
      expect(
        LineSanitizer.overlaps(
          '처음 보는 음식에 먼저 숟가락 대는 사람이다.',
          '처음 보는 음식에 먼저 숟가락 대는 손님',
          9,
        ),
        isTrue,
      );
      expect(
        LineSanitizer.overlaps('샛길로 먼저 들어가는구나.', '해 지기 전에 샛길로 들어간다', 9),
        isFalse,
      );
      expect(LineSanitizer.overlaps('짧다', '짧다', 9), isFalse);
    });

    test('cleanLine 은 내용 속 콜론은 두고 앞 이름표만 뗀다', () {
      expect(LineSanitizer.cleanLine('검객: 칼끝이 곧다: 정말로'), '칼끝이 곧다: 정말로');
      expect(
        LineSanitizer.cleanLine('your standing in the *jianghu* and **honour**.'),
        'your standing in the jianghu and honour.',
      );
    });
  });

  group('LlmNarrationEngine', () {
    test('기본 결과: 프롬프트에 화자/답/말투 예시가 들어가고, 정리된 최대 4줄을 모델 출처로 돌려준다', () async {
      final llm = _ScriptedLlm([
        '빛을 바로 내주지 않는 돌입니다.\n1. 하루를 미루는 손님은 드뭅니다.\n2. 당신은 서두르지 않는 사람이에요.\n3. 그 신중함이 빛을 깊게 하죠.\n4. 다만 너무 오래 재다가 때를 놓치기도 하죠.\n5. 남는 줄',
      ]);
      final engine = LlmNarrationEngine(llm, () async => promptsJson);
      final r = await engine.baseLines(base, Random(3));
      // 말투 예시를 그대로 옮긴 첫 줄은 버리고, 성격 단정 문장은 허용, 4줄까지만.
      expect(
        r.dataOrNull,
        const Narration(
          lines: [
            '하루를 미루는 손님은 드뭅니다.',
            '당신은 서두르지 않는 사람이에요.',
            '그 신중함이 빛을 깊게 하죠.',
            '다만 너무 오래 재다가 때를 놓치기도 하죠.',
          ],
          source: NarrationSource.model,
        ),
      );
      expect(
        llm.prompts.single,
        allOf(
          contains('보석상 주인'),
          contains('하루 생각해 보고 답한다 (신중)'),
          contains('빛을 바로 내주지 않는 돌입니다.'),
          contains('방금 상대에게 한 첫 대사: 당신은 깊은 바다의 사파이어처럼 보이네요.'),
          contains('상대의 성격: 무엇이 잘못될지 먼저 따져 보는 사람이다'),
          contains('약점: 의심이 결정을 늦춘다'),
        ),
      );
      // 유형 이름(이론 이름이 드러나는 라벨)은 프롬프트에 넣지 않는다. 금지 규칙 문장에만 이론 이름이 나온다.
      expect(llm.prompts.single, isNot(contains('6번 · 대비하는 사람')));
      expect(llm.prompts.single, isNot(contains('오늘은 에니어그램')));
      expect(llm.seeds.single, Random(3).nextInt(1 << 31));
    });

    test('채널 말투 규칙이 프롬프트에 들어가고, 채널 금지 표현이 든 줄은 버린다', () async {
      final llm = _ScriptedLlm(['석탄이 압력을 견딘 셈이죠.\n하나.\n둘.\n셋.']);
      final engine = LlmNarrationEngine(llm, () async => promptsJson);
      final r = await engine.baseLines(base, Random(1));
      expect(r.dataOrNull!.lines, ['하나.', '둘.', '셋.']);
      expect(llm.prompts.single, contains('감정 어휘는 하나만 쓴다.'));
    });

    test('context 줄이 프롬프트에 들어간다', () async {
      final llm = _ScriptedLlm(['하나.\n둘.\n셋.', '하나.\n둘.\n셋.']);
      final engine = LlmNarrationEngine(llm, () async => promptsJson);
      const withContext = BaseNarrationRequest(
        languageCode: 'ko',
        speaker: '객잔 주인',
        place: '객잔',
        title: '바람 같은 손',
        answers: [],
        examples: [],
        fallbackLines: [],
        context: ['오래된 벗이다.', '처음 보는 얼굴이다.'],
      );
      await engine.baseLines(withContext, Random(1));
      expect(
        llm.prompts.single,
        contains('네가 이 사람에 대해 아는 것:\n오래된 벗이다.\n처음 보는 얼굴이다.\n'),
      );
      // context 가 없으면 머리줄도 넣지 않는다 (빈 머리줄은 모델이 내용을 지어내게 한다).
      await engine.baseLines(base, Random(1));
      expect(llm.prompts.last, isNot(contains('네가 이 사람에 대해 아는 것')));
      expect(llm.prompts.last, isNot(contains('{context}')));
      expect(llm.prompts.last, contains('의심이 결정을 늦춘다\n네 말투 예시:'));
    });

    test('이야기 요청: 이야기 프롬프트에 상황 없이 고른 행동만, 1줄, 칭호/질문을 되읽는 줄은 버린다', () async {
      final llm = _ScriptedLlm([
        '처음 보는 음식에 먼저 숟가락 대는 사람이다.\n'
            '보따리 진 행상에게서 끝까지 가 본 적 없다는 이야기를 들었더군.\n'
            '샛길로 먼저 들어가는 걸 보니 낯선 걸 반기는구나.\n'
            '손님 많은 날엔 그게 복이지만, 빈 날엔 엉덩이가 들썩이지.\n'
            '셋째 줄.',
      ]);
      final engine = LlmNarrationEngine(llm, () async => promptsJson);
      const story = BaseNarrationRequest(
        languageCode: 'ko',
        speaker: '객잔 주인',
        place: '객잔',
        title: '처음 보는 음식에 먼저 숟가락 대는 손님',
        answers: [
          ('보따리 진 행상에게서 산속 샛길 이야기를 들었다.', '해 지기 전에 샛길로 들어간다', '개방성 높음'),
        ],
        examples: [],
        fallbackLines: [],
        reveal: '처음 보는 음식에 먼저 숟가락 대는 손님. 객잔에서 굴러먹은 눈으로 보면 너는 그렇다.',
        story: true,
        echoes: [
          '처음 보는 음식에 먼저 숟가락 대는 손님. 객잔에서 굴러먹은 눈으로 보면 너는 그렇다.',
          '보따리 진 행상에게서 아무도 끝까지 가 본 적 없다는 산속 샛길 이야기를 들었다.',
        ],
      );
      final r = await engine.baseLines(story, Random(1));
      expect(r.dataOrNull!.lines, ['샛길로 먼저 들어가는 걸 보니 낯선 걸 반기는구나.']);
      final prompt = llm.prompts.single;
      expect(prompt, contains('- 해 지기 전에 샛길로 들어간다 (개방성 높음)'));
      expect(prompt, isNot(contains('산속 샛길 이야기를 들었다')));
      expect(prompt, contains('이어서 바로 할 말 1줄'));
      expect(prompt, isNot(contains('{')));
    });

    test('이야기 요청: 말끝 규칙에 맞지 않는 줄은 버리고, 거부되면 한 번 더 만든다', () async {
      final llm = _ScriptedLlm(['너는 차분한 사람이에요.', '너는 차분한 사람이지.']);
      final engine = LlmNarrationEngine(llm, () async => promptsJson);
      const story = BaseNarrationRequest(
        languageCode: 'ko',
        speaker: '대장장이',
        place: '대장간',
        title: '연장을 제자리에 거는 손',
        answers: [],
        examples: [],
        fallbackLines: [],
        story: true,
        ending: r'(다|지)$',
      );
      final r = await engine.baseLines(story, Random(1));
      expect(r.dataOrNull!.lines, ['너는 차분한 사람이지.']);
      expect(llm.prompts, hasLength(2));
    });

    test('이야기 요청은 한 줄만 남아도 받아들인다', () async {
      final engine = LlmNarrationEngine(
        _ScriptedLlm(['혼자 남은 줄이다.']),
        () async => promptsJson,
      );
      const story = BaseNarrationRequest(
        languageCode: 'ko',
        speaker: '대장장이',
        place: '대장간',
        title: '연장을 제자리에 거는 손',
        answers: [],
        examples: [],
        fallbackLines: [],
        story: true,
      );
      expect((await engine.baseLines(story, Random(1))).dataOrNull!.lines, [
        '혼자 남은 줄이다.',
      ]);
    });

    test('규칙을 통과한 줄이 최소 줄 수보다 적으면 NarrationRejected', () async {
      final engine = LlmNarrationEngine(
        _ScriptedLlm(['이건 신중함을 의미해요.\n좋네요.']),
        () async => promptsJson,
      );
      expect(
        (await engine.baseLines(base, Random(1))).failureOrNull,
        isA<NarrationRejected>(),
      );
    });

    test('LLM 예외와 시간 초과는 Failure', () async {
      final engine = LlmNarrationEngine(
        _ScriptedLlm([Exception('oom')]),
        () async => promptsJson,
      );
      expect((await engine.baseLines(base, Random(1))).isError, isTrue);
      final slow = LlmNarrationEngine(
        _SlowLlm(),
        () async => promptsJson,
        timeout: const Duration(milliseconds: 10),
      );
      expect((await slow.baseLines(base, Random(1))).isError, isTrue);
    });

    test('발현: separate 는 낯선 목소리로 프롬프트를 만들고 재료가 들어간다', () async {
      final llm = _ScriptedLlm([
        '갑자기 떠오르는 게 있어.\n두 번 전엔 칼을 먼저 뽑았지.\n그 버릇은 아직이야.',
      ]);
      final engine = LlmNarrationEngine(llm, () async => promptsJson);
      final r = await engine.manifestation(manifest, Random(1));
      expect(r.dataOrNull!.lines, hasLength(3));
      expect(r.dataOrNull!.source, NarrationSource.model);
      expect(
        llm.prompts.single,
        allOf(
          contains('낯선 목소리'),
          contains('2번 전, 무협'),
          contains('5번 전에도 떠올랐던 기억'),
        ),
      );
    });

    test('프롬프트에 없는 언어는 한국어 설정으로 만든다', () async {
      final llm = _ScriptedLlm(['첫 줄이다.\n둘째 줄이다.\n셋째 줄이다.']);
      final engine = LlmNarrationEngine(llm, () async => promptsJson);
      final r = await engine.baseLines(
        const BaseNarrationRequest(
          languageCode: 'fr',
          speaker: 'S',
          place: 'P',
          title: 'T',
          answers: [],
          examples: [],
          fallbackLines: [],
        ),
        Random(1),
      );
      expect(r.isSuccess, isTrue);
      expect(llm.prompts.single, contains('상대의 결과: T'));
    });
  });

  group('FallbackNarrationEngine', () {
    final template = TemplateNarrationEngine(() async => templatesJson);

    test('모델이 실패하면 콘텐츠 대사와 템플릿 발현 문장', () async {
      final engine = FallbackNarrationEngine(
        LlmNarrationEngine(
          _ScriptedLlm([Exception('x'), Exception('y')]),
          () async => promptsJson,
        ),
        template,
      );
      final b = await engine.baseLines(base, Random(1));
      expect(
        b.dataOrNull,
        const Narration(
          lines: ['콘텐츠 1', '콘텐츠 2'],
          source: NarrationSource.template,
        ),
      );
      final m = await engine.manifestation(manifest, Random(1));
      expect(m.dataOrNull!.source, NarrationSource.template);
      expect(m.dataOrNull!.lines, hasLength(4)); // 도입 + 재료 2 + 마무리
    });

    test('모델 발현 문장에 템플릿 팩의 별도 장면 화자/장소 이름을 붙인다', () async {
      final engine = FallbackNarrationEngine(
        LlmNarrationEngine(
          _ScriptedLlm(['하나.\n둘.\n셋.']),
          () async => promptsJson,
        ),
        template,
      );
      final m = (await engine.manifestation(manifest, Random(1))).dataOrNull!;
      final names =
          (jsonDecode(templatesJson)['languages']['ko'])
              as Map<String, dynamic>;
      expect(m.separateSpeaker, names['separate.speaker']);
      expect(m.separatePlace, names['separate.place']);
      expect(m.lines, ['하나.', '둘.', '셋.']);
    });
  });

  test('TemplateNarrationEngine.baseLines 는 콘텐츠 대사를 그대로', () async {
    final r = await TemplateNarrationEngine(
      () async => templatesJson,
    ).baseLines(base, Random(1));
    expect(r, isA<Success<Narration>>());
    expect(r.dataOrNull!.lines, base.fallbackLines);
  });
}

class _SlowLlm implements LlmClient {
  @override
  Future<String> generate(String prompt, {required int seed}) =>
      Future<String>.delayed(const Duration(seconds: 1), () => 'a\nb');
}
