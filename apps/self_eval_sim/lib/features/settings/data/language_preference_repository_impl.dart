import 'dart:convert';
import 'dart:io';

import 'package:utils/utils.dart';

import '../domain/settings.dart';

class LanguagePreferenceRepositoryImpl implements LanguagePreferenceRepository {
  LanguagePreferenceRepositoryImpl(this._directory);

  static const fileName = 'settings.json';
  final Future<Directory> Function() _directory;

  Future<File> _file() async => File('${(await _directory()).path}/$fileName');

  static Failure _fail(Object e, StackTrace st) =>
      LocalStorageFailure(message: 'settings', cause: e, stackTrace: st);

  @override
  Future<Result<String?>> load() => guardAsync(
        action: () async {
          final file = await _file();
          if (!await file.exists()) return null;
          final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
          final code = json['language'] as String?;
          return SupportedLanguages.codes.contains(code) ? code : null;
        },
        onError: _fail,
      );

  @override
  Future<Result<void>> save(String? languageCode) => guardAsync(
        action: () async {
          final file = await _file();
          await file.parent.create(recursive: true);
          await file.writeAsString(jsonEncode({'language': languageCode}), flush: true);
        },
        onError: _fail,
      );
}
