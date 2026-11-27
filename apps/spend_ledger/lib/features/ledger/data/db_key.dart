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

/// DB 파일은 있는데 키가 없다. 새 키로는 그 DB를 열 수 없으므로 만들지 않는다.
class DbKeyMissingException implements Exception {
  const DbKeyMissingException();

  @override
  String toString() => 'DbKeyMissingException';
}

/// 저장된 키를 읽고, 없으면 32바이트 무작위 키를 만들어 저장한다.
/// 이미 DB가 있는데 키가 없으면 [DbKeyMissingException]을 던진다.
Future<String> loadOrCreateDbKey(
  KeyStore store,
  Random random, {
  required bool databaseExists,
}) async {
  final existing = await store.read();
  if (existing != null) return existing;
  if (databaseExists) throw const DbKeyMissingException();
  final key = base64Encode(List<int>.generate(32, (_) => random.nextInt(256)));
  await store.write(key);
  return key;
}
