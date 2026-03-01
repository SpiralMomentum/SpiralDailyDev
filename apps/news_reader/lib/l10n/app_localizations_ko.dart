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
  String get commentsTitle => '댓글';

  @override
  String get onboardingTitle => '시작하기';

  @override
  String get errorNetwork => '네트워크 오류입니다. 연결 상태를 확인해 주세요.';

  @override
  String get errorServer => '서버 오류입니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get errorUnknown => '예상치 못한 오류가 발생했습니다.';

  @override
  String get errorLocalStorage => '로컬 저장소 오류가 발생했습니다.';

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

  @override
  String get commentHint => '댓글을 입력하세요...';

  @override
  String get commentSend => '보내기';

  @override
  String get commentReply => '답글';

  @override
  String commentCount(int count) {
    return '$count개 댓글';
  }

  @override
  String get articleDetail => '기사 상세';

  @override
  String get share => '공유';

  @override
  String get categoryTechnology => '기술';

  @override
  String get categoryBusiness => '비즈니스';

  @override
  String get categoryScience => '과학';

  @override
  String get categoryHealth => '건강';

  @override
  String get categorySports => '스포츠';

  @override
  String get categoryEntertainment => '엔터테인먼트';

  @override
  String get categoryGeneral => '일반';

  @override
  String get categoryAll => '전체';

  @override
  String get onboardingIntroTitle => '뉴스 리더에 오신 것을 환영합니다';

  @override
  String get onboardingIntroDescription => '관심 있는 뉴스를 모아보고, 북마크하고, 댓글로 소통하세요.';

  @override
  String get onboardingCategoryTitle => '관심 카테고리를 선택하세요';

  @override
  String get onboardingCategoryDescription => '3개 이상 선택해 주세요.';

  @override
  String get onboardingNotificationTitle => '알림을 받으시겠습니까?';

  @override
  String get onboardingNotificationDescription => '새 기사와 댓글 알림을 받을 수 있습니다.';

  @override
  String get onboardingNext => '다음';

  @override
  String get onboardingStart => '시작하기';

  @override
  String get onboardingSkip => '건너뛰기';

  @override
  String get settingsTheme => '테마';

  @override
  String get settingsThemeSystem => '시스템 설정';

  @override
  String get settingsThemeLight => '라이트';

  @override
  String get settingsThemeDark => '다크';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsNotifications => '알림';

  @override
  String get settingsCategories => '관심 카테고리';

  @override
  String get settingsVersion => '버전';

  @override
  String get searchHistory => '최근 검색';

  @override
  String get searchClear => '기록 삭제';

  @override
  String get syncPending => '동기화 대기 중';

  @override
  String get syncComplete => '동기화 완료';

  @override
  String get forcedUpdateTitle => '업데이트가 필요합니다';

  @override
  String get forcedUpdateMessage => '최신 버전으로 업데이트해 주세요.';

  @override
  String get forcedUpdateButton => '업데이트';
}
