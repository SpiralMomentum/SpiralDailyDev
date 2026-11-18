// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Cumulative Rating';

  @override
  String get gateTitle => 'You need to download the model once first';

  @override
  String get gateBody => 'After that, every evaluation works without internet.';

  @override
  String get gateDownload => 'Download';

  @override
  String gateDownloading(int percent) {
    return 'Downloading $percent%';
  }

  @override
  String get gateFailed =>
      'Download failed. Check your connection and try again.';

  @override
  String get gateTooLarge => 'The model is larger than the allowed size.';

  @override
  String get gateRetry => 'Try again';

  @override
  String get homeTitle => 'Where do you want to be evaluated?';

  @override
  String get homeSettings => 'Settings';

  @override
  String quizProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get generatingTitle => 'Making your result';

  @override
  String get generatingAdOffer =>
      'Watch an ad while you wait to get a longer scene';

  @override
  String get generatingWatchAd => 'Watch ad';

  @override
  String get generatingSkipAd => 'Just wait';

  @override
  String adPlaying(int seconds) {
    return 'Ad playing · ${seconds}s';
  }

  @override
  String get adRewarded => 'Bonus scene unlocked';

  @override
  String get adFailed => 'Couldn\'t load the ad';

  @override
  String get resultTapToContinue => 'Tap to continue';

  @override
  String get resultTitleLabel => 'Rating';

  @override
  String get resultShare => 'Share';

  @override
  String get resultAgain => 'Once more';

  @override
  String get resultHome => 'Back to start';

  @override
  String get shareMaking => 'Making share image';

  @override
  String get shareFailed => 'Couldn\'t make the share image';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'Use device setting';

  @override
  String get settingsHistory => 'History';

  @override
  String settingsHistoryCount(int attempts, int manifestations) {
    return 'Tries: $attempts · Manifested: $manifestations';
  }

  @override
  String get settingsDeleteAll => 'Delete all history';

  @override
  String get settingsDeleteConfirmTitle => 'Delete all history?';

  @override
  String get settingsDeleteConfirmBody => 'Deleted history can\'t be restored.';

  @override
  String get settingsDeleted => 'All history deleted';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonError => 'Something went wrong. Please try again.';
}
