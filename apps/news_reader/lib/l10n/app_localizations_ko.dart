// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '뉴스 리더';

  @override
  String get feedTitle => '피드';

  @override
  String get bookmarksTitle => '북마크';

  @override
  String get searchTitle => '검색';

  @override
  String get settingsTitle => '설정';

  @override
  String get errorNetwork => '네트워크 오류입니다. 연결 상태를 확인해 주세요.';

  @override
  String get errorServer => '서버 오류입니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get errorUnknown => '예상치 못한 오류가 발생했습니다.';

  @override
  String get retry => '재시도';

  @override
  String get emptyFeed => '새로운 기사가 없습니다.';

  @override
  String get emptyBookmarks => '저장한 기사가 없습니다.';

  @override
  String get emptySearch => '검색 결과가 없습니다.';

  @override
  String get emptyComments => '첫 댓글을 남겨보세요!';

  @override
  String get bookmarkAdded => '기사를 북마크했습니다.';

  @override
  String get bookmarkRemoved => '북마크를 해제했습니다.';

  @override
  String get searchHint => '기사 검색...';
}
