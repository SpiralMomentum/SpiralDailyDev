import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// integration_test/screenshots_test.dart 가 보낸 스크린샷을 PNG 파일로 저장한다.
/// 저장 위치: 환경변수 SHOT_DIR (기본값 tools/marketing/assets/shots/daily_memo/ko).
Future<void> main() async {
  final dir = Platform.environment['SHOT_DIR'] ??
      '../../tools/marketing/assets/shots/daily_memo/ko';
  await integrationDriver(
    // 테스트가 binding.reportData = {'focus': {name: {'rect': [l, t, r, b], 'dpr': n}}} 로 보낸 초점을
    // <name>.json 사이드카로 남긴다 (iOS 는 takeScreenshot args 미지원).
    responseDataCallback: (Map<String, dynamic>? data) async {
      final focus = (data?['focus'] as Map<String, dynamic>?) ?? {};
      for (final entry in focus.entries) {
        await File('$dir/${entry.key}.json').writeAsString(jsonEncode(entry.value));
      }
    },
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final file = File('$dir/$name.png');
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    },
  );
}
