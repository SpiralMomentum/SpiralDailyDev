import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/app/font_licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registers OFL licenses for the three bundled fonts', () async {
    registerFontLicenses();
    final entries = await LicenseRegistry.licenses.toList();
    final packages = entries.expand((e) => e.packages).toSet();
    expect(
      packages,
      containsAll(['Pretendard', 'Nanum Myeongjo', 'Jua']),
    );
    final text = entries
        .where((e) => e.packages.contains('Jua'))
        .map((e) => e.paragraphs.map((p) => p.text).join())
        .join();
    expect(text, contains('SIL Open Font License'));
  });
}
