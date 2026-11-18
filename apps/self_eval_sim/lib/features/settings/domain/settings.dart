import 'package:utils/utils.dart';

/// 지원 언어 (명세 1절: 한국어, 영어, 일본어, 중국어).
abstract final class SupportedLanguages {
  static const codes = ['ko', 'en', 'ja', 'zh'];
  static const fallback = 'en';

  /// 기기 언어를 지원 언어로 맞춘다. 지원하지 않으면 [fallback].
  static String resolve(String? deviceLanguageCode) =>
      codes.contains(deviceLanguageCode) ? deviceLanguageCode! : fallback;
}

abstract interface class LanguagePreferenceRepository {
  /// null 이면 기기 설정을 따른다.
  Future<Result<String?>> load();
  Future<Result<void>> save(String? languageCode);
}
