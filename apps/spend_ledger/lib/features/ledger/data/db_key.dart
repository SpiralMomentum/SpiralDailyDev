import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class KeyStore {
  Future<String?> read();
  Future<void> write(String v);
}

class SecureKeyStore implements KeyStore {
  const SecureKeyStore([this._storage = const FlutterSecureStorage()]);

  static const _key = 'ledger_db_key';
  static const _ios = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key, iOptions: _ios);

  @override
  Future<void> write(String v) =>
      _storage.write(key: _key, value: v, iOptions: _ios);
}

/// 저장된 키를 읽고, 없으면 32바이트 무작위 키를 만들어 저장한다.
Future<String> loadOrCreateDbKey(KeyStore store, Random random) async {
  final existing = await store.read();
  if (existing != null) return existing;
  final key = base64Encode(List<int>.generate(32, (_) => random.nextInt(256)));
  await store.write(key);
  return key;
}
