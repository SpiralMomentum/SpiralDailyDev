import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

/// 통합 테스트의 reportData 를 build/simulation/report.json 으로 저장한다.
Future<void> main() => integrationDriver(
      timeout: const Duration(hours: 3),
      responseDataCallback: (data) async {
        final file = File(Platform.environment['SIM_REPORT'] ?? 'build/simulation/report.json');
        await file.create(recursive: true);
        await file.writeAsString(const JsonEncoder.withIndent(' ').convert(data));
      },
    );
