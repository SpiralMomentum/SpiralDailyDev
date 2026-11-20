import 'dart:convert';
import 'dart:io';

import 'package:utils/utils.dart';

import '../../domain/story/story_record.dart';
import '../../domain/story/story_repository.dart';
import 'story_record_mapper.dart';

/// 세계마다 `story_<worldId>.json` 파일 하나로 보관한다.
/// 쓰기는 임시 파일에 쓴 뒤 이름을 바꿔, 쓰는 도중 앱이 꺼져도 이전 기록이 깨지지 않게 한다.
class StoryRepositoryImpl implements StoryRepository {
  const StoryRepositoryImpl(this._directory);

  static const _prefix = 'story_';

  final Future<Directory> Function() _directory;

  static Failure _storage(Object e, StackTrace st) =>
      LocalStorageFailure(message: 'story', cause: e, stackTrace: st);

  Future<File> _file(String worldId) async =>
      File('${(await _directory()).path}/$_prefix$worldId.json');

  Future<List<StoryMeeting>> _read(String worldId) async {
    final file = await _file(worldId);
    if (!await file.exists()) return const [];
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return StoryRecordMapper.fromJson(json);
  }

  @override
  Future<Result<List<StoryMeeting>>> load(String worldId) =>
      guardAsync(action: () => _read(worldId), onError: _parseOrStorage);

  @override
  Future<Result<void>> append(String worldId, StoryMeeting meeting) =>
      guardAsync(
        action: () async {
          final meetings = [...await _read(worldId), meeting];
          final file = await _file(worldId);
          await file.parent.create(recursive: true);
          final temp = File('${file.path}.tmp');
          await temp.writeAsString(
            jsonEncode(StoryRecordMapper.toJson(meetings)),
            flush: true,
          );
          await temp.rename(file.path);
        },
        onError: _parseOrStorage,
      );

  @override
  Future<Result<void>> clear() => guardAsync(
    action: () async {
      final dir = await _directory();
      if (!await dir.exists()) return;
      await for (final entity in dir.list()) {
        final name = entity.uri.pathSegments.last;
        if (entity is File &&
            name.startsWith(_prefix) &&
            (name.endsWith('.json') || name.endsWith('.json.tmp'))) {
          await entity.delete();
        }
      }
    },
    onError: _storage,
  );

  static Failure _parseOrStorage(Object e, StackTrace st) =>
      e is FormatException || e is TypeError
      ? ParsingFailure(message: 'story', cause: e, stackTrace: st)
      : _storage(e, st);
}
