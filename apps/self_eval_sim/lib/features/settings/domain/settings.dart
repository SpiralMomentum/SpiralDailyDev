import 'package:utils/utils.dart';

/// 지원 언어. 명세 1절의 4개 언어 중 지금은 한국어만 운영한다.
/// 한국어 서비스가 안정되면 언어를 다시 추가한다 (언어별 파일 구조는 그대로 둠).
abstract final class SupportedLanguages {
  static const codes = ['ko'];
  static const fallback = 'ko';

  /// 기기 언어를 지원 언어로 맞춘다. 지원하지 않으면 [fallback].
  static String resolve(String? deviceLanguageCode) =>
      codes.contains(deviceLanguageCode) ? deviceLanguageCode! : fallback;
}

abstract interface class LanguagePreferenceRepository {
  /// null 이면 기기 설정을 따른다.
  Future<Result<String?>> load();
  Future<Result<void>> save(String? languageCode);
}
