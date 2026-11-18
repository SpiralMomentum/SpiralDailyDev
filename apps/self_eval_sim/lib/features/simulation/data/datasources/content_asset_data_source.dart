import 'dart:convert';

import 'package:flutter/services.dart';

/// 앱에 포함된 콘텐츠 에셋을 읽는다.
class ContentAssetDataSource {
  const ContentAssetDataSource(this._bundle);

  static const structurePath = 'assets/content/structure.json';
  static String stringsPath(String languageCode) =>
      'assets/content/strings/$languageCode.json';

  final AssetBundle _bundle;

  Future<Map<String, dynamic>> structure() async =>
      jsonDecode(await _bundle.loadString(structurePath)) as Map<String, dynamic>;

  Future<Map<String, dynamic>> strings(String languageCode) async =>
      jsonDecode(await _bundle.loadString(stringsPath(languageCode)))
          as Map<String, dynamic>;
}
