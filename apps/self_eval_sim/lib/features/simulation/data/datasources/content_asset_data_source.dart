import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 앱에 포함된 콘텐츠 에셋을 읽는다.
class ContentAssetDataSource {
  const ContentAssetDataSource(this._bundle);

  static const structurePath = 'assets/content/structure.json';
  static String stringsPath(String languageCode) =>
      'assets/content/strings/$languageCode.json';
  static String storyWorldPath(String worldId) =>
      'assets/story/$worldId/world.json';
  static String storyStringsPath(String worldId, String languageCode) =>
      'assets/story/$worldId/$languageCode.json';

  final AssetBundle _bundle;

  Future<Map<String, dynamic>> structure() async =>
      jsonDecode(await _bundle.loadString(structurePath)) as Map<String, dynamic>;

  Future<Map<String, dynamic>> strings(String languageCode) async =>
      jsonDecode(await _bundle.loadString(stringsPath(languageCode)))
          as Map<String, dynamic>;

  /// 이야기 세계 정의. 에셋이 없으면 예외.
  Future<Map<String, dynamic>> storyWorld(String worldId) async =>
      jsonDecode(await _bundle.loadString(storyWorldPath(worldId)))
          as Map<String, dynamic>;

  /// 이야기 문장. 에셋이 없으면 빈 맵, 내용이 깨졌으면 예외.
  Future<Map<String, dynamic>> storyStrings(
    String worldId,
    String languageCode,
  ) async {
    final String raw;
    try {
      raw = await _bundle.loadString(storyStringsPath(worldId, languageCode));
    } on FlutterError {
      return const {};
    }
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
