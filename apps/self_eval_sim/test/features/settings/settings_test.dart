import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/settings/data/language_preference_repository_impl.dart';
import 'package:self_eval_sim/features/settings/domain/settings.dart';

void main() {
  test('SupportedLanguages.resolve: 지금은 한국어만 운영하므로 그 외 언어는 한국어', () {
    expect(SupportedLanguages.codes, ['ko']);
    expect(SupportedLanguages.resolve('ko'), 'ko');
    expect(SupportedLanguages.resolve('en'), 'ko');
    expect(SupportedLanguages.resolve(null), 'ko');
  });

  test('언어 설정 저장/읽기, 지원하지 않는 값은 기기 설정(null)으로', () async {
    final dir = Directory.systemTemp.createTempSync('settings');
    addTearDown(() => dir.deleteSync(recursive: true));
    final repo = LanguagePreferenceRepositoryImpl(() async => dir);
    expect((await repo.load()).dataOrNull, isNull);
    await repo.save('ko');
    expect((await repo.load()).dataOrNull, 'ko');
    await repo.save(null);
    expect((await repo.load()).dataOrNull, isNull);
    File('${dir.path}/settings.json').writeAsStringSync('{"language":"ja"}');
    expect((await repo.load()).dataOrNull, isNull);
    File('${dir.path}/settings.json').writeAsStringSync('broken');
    expect((await repo.load()).isError, isTrue);
  });
}
