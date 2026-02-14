import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko')
  ];

  /// 앱 타이틀
  ///
  /// In ko, this message translates to:
  /// **'데일리 메모'**
  String get appTitle;

  /// 메모 목록 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'메모 목록'**
  String get memoListTitle;

  /// 캘린더 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'캘린더'**
  String get calendarTitle;

  /// 새 메모 작성 버튼 텍스트
  ///
  /// In ko, this message translates to:
  /// **'새 메모'**
  String get newMemo;

  /// 메모 저장 버튼 텍스트
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get saveMemo;

  /// 메모 삭제 버튼 텍스트
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get deleteMemo;

  /// 삭제 실행 버튼 텍스트
  ///
  /// In ko, this message translates to:
  /// **'삭제하기'**
  String get deleteAction;

  /// 메모 삭제 확인 다이얼로그 메시지
  ///
  /// In ko, this message translates to:
  /// **'이 메모를 삭제하시겠습니까?'**
  String get deleteConfirmation;

  /// 메모가 없을 때 표시되는 안내 메시지
  ///
  /// In ko, this message translates to:
  /// **'데이터가 없습니다.'**
  String get noMemos;

  /// 메모 제목 입력 필드 힌트 텍스트
  ///
  /// In ko, this message translates to:
  /// **'제목을 입력하세요'**
  String get memoTitleHint;

  /// 메모 내용 입력 필드 힌트 텍스트
  ///
  /// In ko, this message translates to:
  /// **'내용을 입력하세요'**
  String get memoContentHint;

  /// 메모 제목 라벨
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get titleLabel;

  /// 메모 내용 라벨
  ///
  /// In ko, this message translates to:
  /// **'내용'**
  String get contentLabel;

  /// 제목이 비어있을 때 표시되는 텍스트
  ///
  /// In ko, this message translates to:
  /// **'(빈 제목)'**
  String get emptyTitle;

  /// 내용이 비어있을 때 표시되는 텍스트
  ///
  /// In ko, this message translates to:
  /// **'(빈 내용)'**
  String get emptyContent;

  /// 추가 버튼 텍스트
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get add;

  /// 수정 버튼/타이틀 텍스트
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get edit;

  /// 취소 버튼 텍스트
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// 확인 버튼 텍스트
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get confirm;

  /// 홈 탭 라벨
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get home;

  /// 알림 탭 라벨
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get notifications;

  /// 메모 수정일 표시
  ///
  /// In ko, this message translates to:
  /// **'수정일 {date}'**
  String modifiedDate(String date);

  /// 메모 생성일 표시
  ///
  /// In ko, this message translates to:
  /// **'생성일 {date}'**
  String createdDate(String date);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
