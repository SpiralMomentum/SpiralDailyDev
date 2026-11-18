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
  final templatesJson = File('assets/narration/templates.json').readAsStringSync();

  const base = BaseNarrationRequest(
    languageCode: 'ko',
    speaker: '보석상 주인',
    place: '골목 끝 작은 보석상',
    title: '깊은 바다의 사파이어',
    answers: [('곤란한 부탁을 받았다.', '하루 생각해 보고 답한다')],
    examples: ['빛을 바로 내주지 않는 돌입니다.'],
    fallbackLines: ['콘텐츠 1', '콘텐츠 2'],
  );
  const manifest = ManifestationRequest(
    languageCode: 'ko',
    form: ManifestationForm.separate,
    speaker: '보석상 주인',
    title: '깊은 바다의 사파이어',
    materials: [
      ResolvedMaterial(kind: MaterialKind.attempt, ago: 2, channelName: '무협', choiceText: '검을 뽑는다'),
      ResolvedMaterial(kind: MaterialKind.manifestation, ago: 5, channelName: '보석', choiceText: '사진'),
    ],
  );

  group('LineSanitizer', () {
    List<String> clean(String raw, {int maxLines = 3}) =>
        LineSanitizer.clean(raw, title: '사파이어', maxLength: 20, maxLines: maxLines, banned: [RegExp('당신은.*사람')]);

    test('번호, 글머리표, 이름표, 감싼 따옴표, 특수 토큰, 빈 줄을 걷어낸다', () {
      expect(
        clean('<|channel>1. "첫 줄이다."\n\n- 보석상 주인: 둘째 줄.\n「셋째」<end_of_turn>'),
        ['첫 줄이다.', '둘째 줄.', '셋째'],
      );
    });

    test('결과 이름이 든 줄, 금지 패턴, 길이 1.5배 초과, 중복은 버리고 maxLines 까지만', () {
      expect(
        clean('깊은 바다의 사파이어군요.\n당신은 차분한 사람입니다.\n${'가' * 31}\n좋다.\n좋다.\n하나.\n둘.\n셋.'),
        ['좋다.', '하나.', '둘.'],
      );
    });

    test('cleanLine 은 내용 속 콜론은 두고 앞 이름표만 뗀다', () {
      expect(LineSanitizer.cleanLine('검객: 칼끝이 곧다: 정말로'), '칼끝이 곧다: 정말로');
    });
  });

  group('LlmNarrationEngine', () {
    test('기본 결과: 프롬프트에 화자/답/말투 예시가 들어가고, 정리된 2줄을 모델 출처로 돌려준다', () async {
      final llm = _ScriptedLlm(['1. 하루를 미루는 손님은 드뭅니다.\n2. 그 신중함이 빛을 깊게 하죠.\n3. 남는 줄']);
      final engine = LlmNarrationEngine(llm, () async => promptsJson);
      final r = await engine.baseLines(base, Random(3));
      expect(r.dataOrNull, const Narration(lines: ['하루를 미루는 손님은 드뭅니다.', '그 신중함이 빛을 깊게 하죠.'], source: NarrationSource.model));
      expect(llm.prompts.single, allOf(contains('보석상 주인'), contains('하루 생각해 보고 답한다'), contains('빛을 바로 내주지 않는 돌입니다.')));
      expect(llm.seeds.single, Random(3).nextInt(1 << 31));
    });

    test('규칙을 통과한 줄이 최소 줄 수보다 적으면 NarrationRejected', () async {
      final engine = LlmNarrationEngine(_ScriptedLlm(['당신은 신중한 사람입니다.\n좋네요.']), () async => promptsJson);
      expect((await engine.baseLines(base, Random(1))).failureOrNull, isA<NarrationRejected>());
    });

    test('LLM 예외와 시간 초과는 Failure', () async {
      final engine = LlmNarrationEngine(_ScriptedLlm([Exception('oom')]), () async => promptsJson);
      expect((await engine.baseLines(base, Random(1))).isError, isTrue);
      final slow = LlmNarrationEngine(_SlowLlm(), () async => promptsJson, timeout: const Duration(milliseconds: 10));
      expect((await slow.baseLines(base, Random(1))).isError, isTrue);
    });

    test('발현: separate 는 낯선 목소리로 프롬프트를 만들고 재료가 들어간다', () async {
      final llm = _ScriptedLlm(['갑자기 떠오르는 게 있어.\n두 번 전엔 칼을 먼저 뽑았지.\n그 버릇은 아직이야.']);
      final engine = LlmNarrationEngine(llm, () async => promptsJson);
      final r = await engine.manifestation(manifest, Random(1));
      expect(r.dataOrNull!.lines, hasLength(3));
      expect(r.dataOrNull!.source, NarrationSource.model);
      expect(llm.prompts.single, allOf(contains('낯선 목소리'), contains('2번 전, 무협'), contains('5번 전에도 떠올랐던 기억')));
    });

    test('프롬프트에 없는 언어는 영어 설정으로 만든다', () async {
      final llm = _ScriptedLlm(['Line one here.\nLine two here.']);
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
      expect(llm.prompts.single, contains('in English'));
    });
  });

  group('FallbackNarrationEngine', () {
    final template = TemplateNarrationEngine(() async => templatesJson);

    test('모델이 실패하면 콘텐츠 대사와 템플릿 발현 문장', () async {
      final engine = FallbackNarrationEngine(
        LlmNarrationEngine(_ScriptedLlm([Exception('x'), Exception('y')]), () async => promptsJson),
        template,
      );
      final b = await engine.baseLines(base, Random(1));
      expect(b.dataOrNull, const Narration(lines: ['콘텐츠 1', '콘텐츠 2'], source: NarrationSource.template));
      final m = await engine.manifestation(manifest, Random(1));
      expect(m.dataOrNull!.source, NarrationSource.template);
      expect(m.dataOrNull!.lines, hasLength(4)); // 도입 + 재료 2 + 마무리
    });

    test('모델 발현 문장에 템플릿 팩의 별도 장면 화자/장소 이름을 붙인다', () async {
      final engine = FallbackNarrationEngine(
        LlmNarrationEngine(_ScriptedLlm(['하나.\n둘.\n셋.']), () async => promptsJson),
        template,
      );
      final m = (await engine.manifestation(manifest, Random(1))).dataOrNull!;
      final names = (jsonDecode(templatesJson)['languages']['ko']) as Map<String, dynamic>;
      expect(m.separateSpeaker, names['separate.speaker']);
      expect(m.separatePlace, names['separate.place']);
      expect(m.lines, ['하나.', '둘.', '셋.']);
    });
  });

  test('TemplateNarrationEngine.baseLines 는 콘텐츠 대사를 그대로', () async {
    final r = await TemplateNarrationEngine(() async => templatesJson).baseLines(base, Random(1));
    expect(r, isA<Success<Narration>>());
    expect(r.dataOrNull!.lines, base.fallbackLines);
  });
}

class _SlowLlm implements LlmClient {
  @override
  Future<String> generate(String prompt, {required int seed}) =>
      Future<String>.delayed(const Duration(seconds: 1), () => 'a\nb');
}
