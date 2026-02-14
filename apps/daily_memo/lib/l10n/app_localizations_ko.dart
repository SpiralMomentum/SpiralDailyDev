// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '데일리 메모';

  @override
  String get memoListTitle => '메모 목록';

  @override
  String get calendarTitle => '캘린더';

  @override
  String get newMemo => '새 메모';

  @override
  String get saveMemo => '저장';

  @override
  String get deleteMemo => '삭제';

  @override
  String get deleteAction => '삭제하기';

  @override
  String get deleteConfirmation => '이 메모를 삭제하시겠습니까?';

  @override
  String get noMemos => '데이터가 없습니다.';

  @override
  String get memoTitleHint => '제목을 입력하세요';

  @override
  String get memoContentHint => '내용을 입력하세요';

  @override
  String get titleLabel => '제목';

  @override
  String get contentLabel => '내용';

  @override
  String get emptyTitle => '(빈 제목)';

  @override
  String get emptyContent => '(빈 내용)';

  @override
  String get add => '추가';

  @override
  String get edit => '수정';

  @override
  String get cancel => '취소';

  @override
  String get confirm => '확인';

  @override
  String get home => '홈';

  @override
  String get notifications => '알림';

  @override
  String modifiedDate(String date) {
    return '수정일 $date';
  }

  @override
  String createdDate(String date) {
    return '생성일 $date';
  }
}
