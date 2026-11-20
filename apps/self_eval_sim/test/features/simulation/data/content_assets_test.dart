import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/settings/domain/settings.dart';
import 'package:self_eval_sim/features/simulation/data/datasources/content_asset_data_source.dart';
import 'package:self_eval_sim/features/simulation/data/engine/prompt_builder.dart';
import 'package:self_eval_sim/features/simulation/data/engine/template_narration_engine.dart';
import 'package:self_eval_sim/features/simulation/data/mappers/catalog_mapper.dart';
import 'package:self_eval_sim/features/simulation/data/repositories/content_repository_impl.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/accumulation.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/catalog.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/evaluation.dart';
import 'package:utils/utils.dart';

import '../../../support/story_fixtures.dart';

/// 경로 -> 내용 맵으로 동작하는 번들. 없는 경로는 실제 번들처럼 FlutterError.
class _MapBundle extends CachingAssetBundle {
  _MapBundle(this.files);

  final Map<String, String> files;
  final loads = <String, int>{};

  @override
  Future<ByteData> load(String key) async {
    final content = files[key];
    if (content == null) throw FlutterError('Unable to load asset: "$key".');
    loads[key] = (loads[key] ?? 0) + 1;
    return ByteData.sublistView(utf8.encode(content));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final data = await load(key);
    return utf8.decode(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }
}

/// 실제 콘텐츠 에셋(운영 언어 전부)과 문장 팩의 정합성을 검사한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const languages = SupportedLanguages.codes;
  Map<String, dynamic> readJson(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  final catalog = CatalogMapper.catalog(
    readJson(ContentAssetDataSource.structurePath),
  );

  test('채널 4개, 채널별 6문항 x 3선택지, 유형 번호는 0~3', () {
    expect(catalog.channels.map((c) => c.id), [
      'wuxia',
      'fantasy',
      'animal',
      'gem',
    ]);
    for (final c in catalog.channels) {
      expect(c.questions, hasLength(6));
      for (final q in c.questions) {
        expect(q.choices, hasLength(3));
        expect(
          q.choices.every(
            (x) => x.archetype >= 0 && x.archetype < c.archetypeCount,
          ),
          isTrue,
        );
      }
    }
    expect(catalog.questionsPerAttempt, 4);
  });

  test('채널마다 모든 유형(0~3)이 선택지로 도달 가능하다', () {
    for (final c in catalog.channels) {
      final reachable = {
        for (final q in c.questions)
          for (final x in q.choices) x.archetype,
      };
      expect(reachable, {0, 1, 2, 3}, reason: c.id);
    }
  });

  /// 이론의 모든 유형 키. dominant 는 극 하나, code 는 축별 극의 모든 조합.
  List<String> outcomesOf(Theory t) => switch (t.mode) {
    TheoryMode.dominant => [for (final a in t.axes) ...a],
    TheoryMode.code => t.axes.fold<List<String>>(
      [''],
      (acc, axis) => [
        for (final p in acc)
          for (final x in axis) '$p$x',
      ],
    ),
  };

  test('성격 이론 4종: 빅파이브(10극), 16유형(4축), 에니어그램(9), 4기질(4)', () {
    expect(catalog.theories.map((t) => t.id), [
      'bigfive',
      'type16',
      'enneagram',
      'temperament',
    ]);
    expect(catalog.theories.map((t) => outcomesOf(t).length), [10, 16, 9, 4]);
  });

  test('모든 선택지가 모든 이론의 성향 태그를 갖고, 태그는 이론에 정의된 극이다', () {
    for (final c in catalog.channels) {
      for (final q in c.questions) {
        for (final x in q.choices) {
          for (final t in catalog.theories) {
            final poles = x.traits[t.id] ?? const [];
            final defined = {for (final a in t.axes) ...a};
            expect(
              poles,
              isNotEmpty,
              reason: '${c.id}.${q.id}.${x.id} ${t.id}',
            );
            expect(
              defined.containsAll(poles),
              isTrue,
              reason: '${c.id}.${q.id}.${x.id} $poles',
            );
          }
        }
      }
    }
  });

  test('dominant 이론의 모든 극이 최소 2개 선택지에서 드러난다 (유형 도달 가능)', () {
    for (final t in catalog.theories.where(
      (t) => t.mode == TheoryMode.dominant,
    )) {
      final counts = <String, int>{};
      for (final c in catalog.channels) {
        for (final q in c.questions) {
          for (final x in q.choices) {
            for (final p in x.traits[t.id]!) {
              counts[p] = (counts[p] ?? 0) + 1;
            }
          }
        }
      }
      // 빅파이브의 낮은 극(C-) 등은 반대 극 점수가 음수일 때 이길 수 있어 0 이어도 되지만,
      // 한쪽 극만 있는 이론(에니어그램, 4기질)은 모든 유형이 실제로 태그되어야 한다.
      for (final axis in t.axes.where((a) => a.length == 1)) {
        expect(
          counts[axis.single] ?? 0,
          greaterThanOrEqualTo(2),
          reason: '${t.id} ${axis.single}',
        );
      }
    }
  });

  for (final lang in languages) {
    test('[$lang] 구조가 요구하는 문장 키가 모두 있고 비어 있지 않다', () {
      final text = CatalogMapper.textBook(
        lang,
        readJson(ContentAssetDataSource.stringsPath(lang)),
      );
      final required = <String>[
        for (final c in catalog.channels) ...[
          '${c.id}.name',
          '${c.id}.tagline',
          '${c.id}.speaker',
          '${c.id}.place',
          '${c.id}.reveal',
          '${c.id}.style',
          '${c.id}.avoid',
          '${c.id}.ext.place',
          '${c.id}.ext1',
          '${c.id}.ext2',
          for (var a = 0; a < c.archetypeCount; a++) ...[
            '${c.id}.a$a.title',
            '${c.id}.a$a.line1',
            '${c.id}.a$a.line2',
            '${c.id}.a$a.saying1',
            '${c.id}.a$a.saying2',
            '${c.id}.a$a.saying3',
          ],
          for (final q in c.questions) ...[
            '${c.id}.${q.id}',
            for (final x in q.choices) '${c.id}.${q.id}.${x.id}',
          ],
        ],
        for (final t in catalog.theories) ...[
          'theory.${t.id}.name',
          if (t.mode == TheoryMode.code)
            for (final a in t.axes)
              for (final p in a) 'theory.${t.id}.$p.label',
          for (final o in outcomesOf(t))
            for (final f in ['label', 'desc', 'strength', 'weakness'])
              'theory.${t.id}.$o.$f',
        ],
      ];
      final missing = required
          .where((k) => (text.entries[k] ?? '').trim().isEmpty)
          .toList();
      expect(missing, isEmpty);
      expect(
        text.entries.keys.toSet(),
        required.toSet(),
        reason: '쓰이지 않는 키가 없어야 한다',
      );
    });
  }

  final pack = readJson('assets/narration/templates.json');
  const packKeys = [
    'mixed.intro',
    'recall.attempt',
    'recall.manifest',
    'close',
    'separate.speaker',
    'separate.place',
    'separate.intro',
  ];

  for (final lang in languages) {
    test('[$lang] 문장 팩 키가 모두 있고, 재료 템플릿은 {choice} 를 쓴다', () {
      final t =
          (pack['languages'] as Map<String, dynamic>)[lang]
              as Map<String, dynamic>;
      expect(t.keys.toSet(), packKeys.toSet());
      for (final key in ['recall.attempt', 'recall.manifest']) {
        for (final template in (t[key] as List).cast<String>()) {
          expect(template, contains('{choice}'));
        }
      }
    });

    test('[$lang] 템플릿 엔진이 자리표시자를 남기지 않고 intro + 재료 수 + close 줄을 만든다', () async {
      final engine = TemplateNarrationEngine(() async => jsonEncode(pack));
      for (final form in ManifestationForm.values) {
        final r = await engine.manifestation(
          ManifestationRequest(
            languageCode: lang,
            form: form,
            speaker: 'S',
            title: 'T',
            materials: const [
              ResolvedMaterial(
                kind: MaterialKind.attempt,
                ago: 3,
                channelName: 'CH',
                choiceText: 'PICK',
              ),
              ResolvedMaterial(
                kind: MaterialKind.manifestation,
                ago: 1,
                channelName: 'CH',
                choiceText: 'OLD',
              ),
            ],
          ),
          Random(4),
        );
        final lines = r.dataOrNull!.lines;
        expect(lines, hasLength(4));
        expect(lines.join(), isNot(contains('{')));
        expect(lines[1], contains('PICK'));
        expect(lines[2], contains('OLD'));
      }
    });
  }

  test('팩에 없는 언어는 ParsingFailure', () async {
    final engine = TemplateNarrationEngine(() async => jsonEncode(pack));
    final r = await engine.manifestation(
      const ManifestationRequest(
        languageCode: 'fr',
        form: ManifestationForm.mixed,
        speaker: 'S',
        title: 'T',
        materials: [],
      ),
      Random(1),
    );
    expect(r.failureOrNull, isA<ParsingFailure>());
  });

  final prompts = readJson('assets/narration/prompts.json');
  for (final lang in languages) {
    test('[$lang] 프롬프트: 필수 키, 금지 패턴 정규식 컴파일, 자리표시자가 모두 채워진다', () {
      final spec = PromptSpec(
        (prompts['languages'] as Map<String, dynamic>)[lang]
            as Map<String, dynamic>,
      );
      expect(spec.banned, isNotEmpty);
      final text = CatalogMapper.textBook(
        lang,
        readJson(ContentAssetDataSource.stringsPath(lang)),
      );
      final base = PromptBuilder.base(
        spec,
        BaseNarrationRequest(
          languageCode: lang,
          speaker: text.speaker('gem'),
          place: text.place('gem'),
          title: text.archetypeTitle('gem', 1),
          answers: [
            (text.question('gem', 'q1'), text.choice('gem', 'q1', 'c2'), 'x'),
          ],
          examples: text.archetypeLines('gem', 0),
          fallbackLines: text.archetypeLines('gem', 1),
        ),
      );
      final manifest = PromptBuilder.manifestation(
        spec,
        ManifestationRequest(
          languageCode: lang,
          form: ManifestationForm.separate,
          speaker: text.speaker('gem'),
          title: text.archetypeTitle('gem', 1),
          materials: const [
            ResolvedMaterial(
              kind: MaterialKind.attempt,
              ago: 2,
              channelName: 'CH',
              choiceText: 'PICK',
            ),
          ],
        ),
      );
      for (final p in [base, manifest]) {
        expect(RegExp(r'\{[a-zA-Z]+\}').hasMatch(p), isFalse, reason: p);
      }
      expect(base, contains(text.choice('gem', 'q1', 'c2')));
      expect(manifest, contains('PICK'));
      expect(manifest, contains(spec.separateVoice));
      expect(manifest, contains(spec.separateStyle));
      if (lang != 'ko') {
        // 영어 지시문을 쓰는 언어는 성격 단정 문장의 그 언어 형태를 따로 준다.
        expect(spec.judge, isNotEmpty);
        expect(base, contains(spec.judge));
        expect(manifest, contains(spec.judge));
      }
    });
  }

  test('이야기 파일이 없으면 기본 문장만, 있으면 합친다. 세계는 캐시한다', () async {
    final bare = ContentRepositoryImpl(
      ContentAssetDataSource(_MapBundle({
        ContentAssetDataSource.stringsPath('ko'): '{"wuxia.name": "무협"}',
      })),
    );
    expect((await bare.loadText('ko')).dataOrNull!.entries, {'wuxia.name': '무협'});
    expect((await bare.loadStoryWorld('wuxia')).isError, isTrue);

    final bundle = _MapBundle({
      ContentAssetDataSource.stringsPath('ko'): '{"wuxia.name": "무협"}',
      ContentAssetDataSource.storyStringsPath('wuxia', 'ko'):
          '{"story.wuxia.name": "강호"}',
      ContentAssetDataSource.storyWorldPath('wuxia'): jsonEncode(
        miniWorldJson,
      ),
    });
    final repo = ContentRepositoryImpl(ContentAssetDataSource(bundle));
    expect((await repo.loadText('ko')).dataOrNull!.entries, {
      'wuxia.name': '무협',
      'story.wuxia.name': '강호',
    });
    final first = await repo.loadStoryWorld('wuxia');
    final second = await repo.loadStoryWorld('wuxia');
    expect(first.dataOrNull, miniWorld);
    expect(identical(first.dataOrNull, second.dataOrNull), isTrue);
    expect(bundle.loads[ContentAssetDataSource.storyWorldPath('wuxia')], 1);

    // 이야기 문장 파일이 깨졌으면 숨기지 않고 실패.
    final broken = ContentRepositoryImpl(
      ContentAssetDataSource(_MapBundle({
        ContentAssetDataSource.stringsPath('ko'): '{}',
        ContentAssetDataSource.storyStringsPath('wuxia', 'ko'): '{',
      })),
    );
    expect((await broken.loadText('ko')).failureOrNull, isA<ParsingFailure>());
  });

  test('ContentRepositoryImpl 은 번들에서 카탈로그를 읽고 캐시한다', () async {
    final repo = ContentRepositoryImpl(ContentAssetDataSource(rootBundle));
    final first = await repo.loadCatalog();
    final second = await repo.loadCatalog();
    expect(first.dataOrNull!.channels, hasLength(4));
    expect(identical(first.dataOrNull, second.dataOrNull), isTrue);
    expect(
      (await repo.loadText('ko')).dataOrNull!.channelName('gem'),
      isNotEmpty,
    );
    expect((await repo.loadText('xx')).failureOrNull, isA<ParsingFailure>());
  });
}
