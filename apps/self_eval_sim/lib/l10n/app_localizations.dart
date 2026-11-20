import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  static const List<Locale> supportedLocales = <Locale>[Locale('ko')];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'누적 평가'**
  String get appTitle;

  /// No description provided for @gateTitle.
  ///
  /// In ko, this message translates to:
  /// **'처음 한 번, 모델을 내려받아야 해요'**
  String get gateTitle;

  /// No description provided for @gateBody.
  ///
  /// In ko, this message translates to:
  /// **'내려받은 뒤에는 인터넷 없이도 모든 평가가 동작합니다.'**
  String get gateBody;

  /// No description provided for @gateDownload.
  ///
  /// In ko, this message translates to:
  /// **'내려받기'**
  String get gateDownload;

  /// No description provided for @gateDownloading.
  ///
  /// In ko, this message translates to:
  /// **'내려받는 중 {percent}%'**
  String gateDownloading(int percent);

  /// No description provided for @gateFailed.
  ///
  /// In ko, this message translates to:
  /// **'내려받지 못했어요. 연결을 확인하고 다시 시도해 주세요.'**
  String get gateFailed;

  /// No description provided for @gateTooLarge.
  ///
  /// In ko, this message translates to:
  /// **'모델 용량이 허용 상한을 넘었어요.'**
  String get gateTooLarge;

  /// No description provided for @gateRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get gateRetry;

  /// No description provided for @homeTitle.
  ///
  /// In ko, this message translates to:
  /// **'어디에서 평가받을까요?'**
  String get homeTitle;

  /// No description provided for @homeSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get homeSettings;

  /// No description provided for @quizProgress.
  ///
  /// In ko, this message translates to:
  /// **'{current} / {total}'**
  String quizProgress(int current, int total);

  /// No description provided for @generatingTitle.
  ///
  /// In ko, this message translates to:
  /// **'결과를 만드는 중'**
  String get generatingTitle;

  /// No description provided for @generatingAdOffer.
  ///
  /// In ko, this message translates to:
  /// **'기다리는 동안 광고를 보면 장면이 더 길어져요'**
  String get generatingAdOffer;

  /// No description provided for @generatingWatchAd.
  ///
  /// In ko, this message translates to:
  /// **'광고 보기'**
  String get generatingWatchAd;

  /// No description provided for @generatingSkipAd.
  ///
  /// In ko, this message translates to:
  /// **'그냥 기다리기'**
  String get generatingSkipAd;

  /// No description provided for @adPlaying.
  ///
  /// In ko, this message translates to:
  /// **'광고 재생 중 · {seconds}초'**
  String adPlaying(int seconds);

  /// No description provided for @adRewarded.
  ///
  /// In ko, this message translates to:
  /// **'추가 장면이 열렸어요'**
  String get adRewarded;

  /// No description provided for @adFailed.
  ///
  /// In ko, this message translates to:
  /// **'광고를 불러오지 못했어요'**
  String get adFailed;

  /// No description provided for @resultTapToContinue.
  ///
  /// In ko, this message translates to:
  /// **'탭해서 계속'**
  String get resultTapToContinue;

  /// No description provided for @resultTitleLabel.
  ///
  /// In ko, this message translates to:
  /// **'평가'**
  String get resultTitleLabel;

  /// No description provided for @resultShare.
  ///
  /// In ko, this message translates to:
  /// **'공유'**
  String get resultShare;

  /// No description provided for @resultReport.
  ///
  /// In ko, this message translates to:
  /// **'대사 신고'**
  String get resultReport;

  /// No description provided for @reportCopied.
  ///
  /// In ko, this message translates to:
  /// **'메일 앱을 열 수 없어 신고 내용을 복사했어요. {email} 로 보내 주세요.'**
  String reportCopied(String email);

  /// No description provided for @resultAgain.
  ///
  /// In ko, this message translates to:
  /// **'한 번 더'**
  String get resultAgain;

  /// No description provided for @resultHome.
  ///
  /// In ko, this message translates to:
  /// **'처음으로'**
  String get resultHome;

  /// No description provided for @shareMaking.
  ///
  /// In ko, this message translates to:
  /// **'공유 이미지를 만드는 중'**
  String get shareMaking;

  /// No description provided for @shareFailed.
  ///
  /// In ko, this message translates to:
  /// **'공유 이미지를 만들지 못했어요'**
  String get shareFailed;

  /// No description provided for @settingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In ko, this message translates to:
  /// **'기기 설정 따르기'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsHistory.
  ///
  /// In ko, this message translates to:
  /// **'누적 기록'**
  String get settingsHistory;

  /// No description provided for @settingsHistoryCount.
  ///
  /// In ko, this message translates to:
  /// **'시행 {attempts}회 · 발현 {manifestations}회'**
  String settingsHistoryCount(int attempts, int manifestations);

  /// No description provided for @settingsDeleteAll.
  ///
  /// In ko, this message translates to:
  /// **'기록 전체 삭제'**
  String get settingsDeleteAll;

  /// No description provided for @settingsDeleteConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'기록을 모두 지울까요?'**
  String get settingsDeleteConfirmTitle;

  /// No description provided for @settingsDeleteConfirmBody.
  ///
  /// In ko, this message translates to:
  /// **'지운 기록은 되돌릴 수 없어요.'**
  String get settingsDeleteConfirmBody;

  /// No description provided for @settingsDeleted.
  ///
  /// In ko, this message translates to:
  /// **'기록을 모두 지웠어요'**
  String get settingsDeleted;

  /// No description provided for @commonCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get commonDelete;

  /// No description provided for @commonError.
  ///
  /// In ko, this message translates to:
  /// **'문제가 생겼어요. 다시 시도해 주세요.'**
  String get commonError;
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
      <String>['ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
