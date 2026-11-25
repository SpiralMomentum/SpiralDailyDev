import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _fontLicenses = {
  'Pretendard': 'assets/fonts/OFL-Pretendard.txt',
  'Nanum Myeongjo': 'assets/fonts/OFL-NanumMyeongjo.txt',
  'Jua': 'assets/fonts/OFL-Jua.txt',
};

/// 번들 폰트의 OFL 전문을 라이선스 화면에 등록한다. 앱 시작 시 한 번 호출한다.
void registerFontLicenses({AssetBundle? bundle}) {
  for (final entry in _fontLicenses.entries) {
    LicenseRegistry.addLicense(() async* {
      final text = await (bundle ?? rootBundle).loadString(entry.value);
      yield LicenseEntryWithLineBreaks([entry.key], text);
    });
  }
}
