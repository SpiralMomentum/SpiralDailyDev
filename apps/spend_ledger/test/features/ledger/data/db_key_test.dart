import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/ledger/data/db_key.dart';

class FakeKeyStore implements KeyStore {
  String? value;
  int writes = 0;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String v) async {
    writes++;
    value = v;
  }
}

void main() {
  test('key created once and reused', () async {
    final store = FakeKeyStore();
    final k1 = await loadOrCreateDbKey(store, Random(1), databaseExists: false);
    final k2 = await loadOrCreateDbKey(store, Random(2), databaseExists: true);
    expect(k2, k1);
    expect(store.writes, 1);
    expect(base64Decode(k1), hasLength(32));
  });

  test('existing database without a key throws instead of creating', () async {
    final store = FakeKeyStore();
    await expectLater(
      loadOrCreateDbKey(store, Random(1), databaseExists: true),
      throwsA(isA<DbKeyMissingException>()),
    );
    expect(store.writes, 0);
    expect(store.value, isNull);
  });

  test('new database without a key creates one', () async {
    final store = FakeKeyStore();
    final k = await loadOrCreateDbKey(store, Random(1), databaseExists: false);
    expect(store.value, k);
    expect(store.writes, 1);
  });
}
