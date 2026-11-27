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
    final k1 = await loadOrCreateDbKey(store, Random(1));
    final k2 = await loadOrCreateDbKey(store, Random(2));
    expect(k2, k1);
    expect(store.writes, 1);
    expect(base64Decode(k1), hasLength(32));
  });
}
