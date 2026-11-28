import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _domains = ['root', 'file', 'database', 'sharedpref', 'external'];

String _read(String path) =>
    File('android/app/src/main/$path').readAsStringSync();

bool _excludesAll(String xml) => _domains.every(
  (d) => RegExp('<exclude\\s+domain="$d"\\s+path="\\."\\s*/>').hasMatch(xml),
);

String _section(String xml, String tag) {
  final m = RegExp('<$tag>([\\s\\S]*?)</$tag>').firstMatch(xml);
  expect(m, isNotNull, reason: '$tag missing');
  return m!.group(1)!;
}

void main() {
  test('manifest disables backup and points at exclusion rules', () {
    final manifest = _read('AndroidManifest.xml');

    expect(manifest, contains('android:allowBackup="false"'));
    expect(
      manifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );
    expect(manifest, contains('android:fullBackupContent="@xml/backup_rules"'));
  });

  test(
    'data extraction rules exclude every domain from cloud and transfer',
    () {
      final xml = _read('res/xml/data_extraction_rules.xml');

      expect(_excludesAll(_section(xml, 'cloud-backup')), isTrue);
      expect(_excludesAll(_section(xml, 'device-transfer')), isTrue);
    },
  );

  test('legacy backup rules exclude every domain', () {
    final xml = _read('res/xml/backup_rules.xml');

    expect(_excludesAll(_section(xml, 'full-backup-content')), isTrue);
  });
}
