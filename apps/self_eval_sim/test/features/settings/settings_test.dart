import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/settings/data/language_preference_repository_impl.dart';
import 'package:self_eval_sim/features/settings/domain/settings.dart';

void main() {
  test('SupportedLanguages.resolve: 지원 언어는 그대로, 그 외는 영어', () {
    expect(SupportedLanguages.resolve('ko'), 'ko');
    expect(SupportedLanguages.resolve('zh'), 'zh');
    expect(SupportedLanguages.resolve('fr'), 'en');
    expect(SupportedLanguages.resolve(null), 'en');
  });

  test('언어 설정 저장/읽기, 지원하지 않는 값은 기기 설정(null)으로', () async {
    final dir = Directory.systemTemp.createTempSync('settings');
    addTearDown(() => dir.deleteSync(recursive: true));
    final repo = LanguagePreferenceRepositoryImpl(() async => dir);
    expect((await repo.load()).dataOrNull, isNull);
    await repo.save('ja');
    expect((await repo.load()).dataOrNull, 'ja');
    await repo.save(null);
    expect((await repo.load()).dataOrNull, isNull);
    File('${dir.path}/settings.json').writeAsStringSync('{"language":"fr"}');
    expect((await repo.load()).dataOrNull, isNull);
    File('${dir.path}/settings.json').writeAsStringSync('broken');
    expect((await repo.load()).isError, isTrue);
  });
}
