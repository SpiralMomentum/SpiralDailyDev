import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/simulation/data/datasources/content_asset_data_source.dart';
import 'package:self_eval_sim/features/simulation/data/engine/prompt_builder.dart';
import 'package:self_eval_sim/features/simulation/data/engine/template_narration_engine.dart';
import 'package:self_eval_sim/features/simulation/data/mappers/catalog_mapper.dart';
import 'package:self_eval_sim/features/simulation/data/repositories/content_repository_impl.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/accumulation.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/evaluation.dart';
import 'package:utils/utils.dart';

/// 실제 콘텐츠 에셋(4개 언어)과 문장 팩의 정합성을 검사한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const languages = ['ko', 'en', 'ja', 'zh'];
  Map<String, dynamic> readJson(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  final catalog = CatalogMapper.catalog(readJson(ContentAssetDataSource.structurePath));

  test('채널 4개, 채널별 6문항 x 3선택지, 유형 번호는 0~3', () {
    expect(catalog.channels.map((c) => c.id), ['wuxia', 'fantasy', 'animal', 'gem']);
    for (final c in catalog.channels) {
      expect(c.questions, hasLength(6));
      for (final q in c.questions) {
        expect(q.choices, hasLength(3));
        expect(q.choices.every((x) => x.archetype >= 0 && x.archetype < c.archetypeCount), isTrue);
      }
    }
    expect(catalog.questionsPerAttempt, 4);
  });

  test('채널마다 모든 유형(0~3)이 선택지로 도달 가능하다', () {
    for (final c in catalog.channels) {
      final reachable = {for (final q in c.questions) for (final x in q.choices) x.archetype};
      expect(reachable, {0, 1, 2, 3}, reason: c.id);
    }
  });

  for (final lang in languages) {
    test('[$lang] 구조가 요구하는 문장 키가 모두 있고 비어 있지 않다', () {
      final text = CatalogMapper.textBook(lang, readJson(ContentAssetDataSource.stringsPath(lang)));
      final required = <String>[
        for (final c in catalog.channels) ...[
          '${c.id}.name', '${c.id}.tagline', '${c.id}.speaker', '${c.id}.place',
          '${c.id}.ext.place', '${c.id}.ext1', '${c.id}.ext2',
          for (var a = 0; a < c.archetypeCount; a++) ...[
            '${c.id}.a$a.title', '${c.id}.a$a.line1', '${c.id}.a$a.line2',
          ],
          for (final q in c.questions) ...[
            '${c.id}.${q.id}',
            for (final x in q.choices) '${c.id}.${q.id}.${x.id}',
          ],
        ],
      ];
      final missing = required.where((k) => (text.entries[k] ?? '').trim().isEmpty).toList();
      expect(missing, isEmpty);
      expect(text.entries.keys.toSet(), required.toSet(), reason: '쓰이지 않는 키가 없어야 한다');
    });
  }

  final pack = readJson('assets/narration/templates.json');
  const packKeys = [
    'mixed.intro', 'recall.attempt', 'recall.manifest', 'close',
    'separate.speaker', 'separate.place', 'separate.intro',
  ];

  for (final lang in languages) {
    test('[$lang] 문장 팩 키가 모두 있고, 재료 템플릿은 {choice} 를 쓴다', () {
      final t = (pack['languages'] as Map<String, dynamic>)[lang] as Map<String, dynamic>;
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
              ResolvedMaterial(kind: MaterialKind.attempt, ago: 3, channelName: 'CH', choiceText: 'PICK'),
              ResolvedMaterial(kind: MaterialKind.manifestation, ago: 1, channelName: 'CH', choiceText: 'OLD'),
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
      final spec = PromptSpec((prompts['languages'] as Map<String, dynamic>)[lang] as Map<String, dynamic>);
      expect(spec.banned, isNotEmpty);
      final text = CatalogMapper.textBook(lang, readJson(ContentAssetDataSource.stringsPath(lang)));
      final base = PromptBuilder.base(
        spec,
        BaseNarrationRequest(
          languageCode: lang,
          speaker: text.speaker('gem'),
          place: text.place('gem'),
          title: text.archetypeTitle('gem', 1),
          answers: [(text.question('gem', 'q1'), text.choice('gem', 'q1', 'c2'))],
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
            ResolvedMaterial(kind: MaterialKind.attempt, ago: 2, channelName: 'CH', choiceText: 'PICK'),
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
    });
  }

  test('ContentRepositoryImpl 은 번들에서 카탈로그를 읽고 캐시한다', () async {
    final repo = ContentRepositoryImpl(ContentAssetDataSource(rootBundle));
    final first = await repo.loadCatalog();
    final second = await repo.loadCatalog();
    expect(first.dataOrNull!.channels, hasLength(4));
    expect(identical(first.dataOrNull, second.dataOrNull), isTrue);
    expect((await repo.loadText('zh')).dataOrNull!.channelName('gem'), isNotEmpty);
    expect((await repo.loadText('xx')).failureOrNull, isA<ParsingFailure>());
  });
}
