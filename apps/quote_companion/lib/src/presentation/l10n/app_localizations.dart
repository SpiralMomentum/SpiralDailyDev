import 'package:flutter/widgets.dart';

/// Basic localization class until ARB generation is introduced.
class AppLocalizations {
  /// Creates [AppLocalizations].
  AppLocalizations(this.locale);

  /// Current locale.
  final Locale locale;

  static const Map<String, Map<String, String>> _localizedValues =
      <String, Map<String, String>>{
    'en': <String, String>{
      'appTitle': 'Quote Companion',
      'brandSubtitle': 'LINEUP turns inspiration into everyday action.',
      'quoteInputLabel': 'Your quote',
      'authorInputLabel': 'Author (optional)',
      'addQuoteCta': 'Add quote',
      'quoteInputTitle': 'Add your line',
      'customQuotesHeader': 'Your library',
      'channelSettingsTitle': 'Delivery channels',
      'preferencesHeader': 'Display preferences',
      'statusBarLabel': 'Status bar',
      'lockScreenLabel': 'Lock screen',
      'homeWidgetLabel': 'Widget',
      'refreshIntervalLabel': 'Refresh every',
      'minutesSuffix': 'minutes',
      'refreshAction': 'Refresh now',
      'feedbackHeader': 'Share quick feedback',
      'feedbackHint': 'Tell us what you think',
      'feedbackSubmitCta': 'Submit feedback',
      'ratingLabel': 'Satisfaction (1-5)',
      'emailHint': 'Email (optional)',
      'emptyQuotesPlaceholder': 'Add a quote to see it here.',
      'previewHeader': 'Preview surfaces',
      'surfaceDisabledHint': 'Enable this surface above to preview.',
      'quotePlaceholderHeadline': 'Tap refresh to load a new quote.',
    },
    'ko': <String, String>{
      'appTitle': '명언 컴패니언',
      'brandSubtitle': 'LINEUP은 영감을 행동으로 옮기도록 돕는 가장 빠른 방법이에요.',
      'quoteInputLabel': '명언 내용',
      'authorInputLabel': '작성자 (선택)',
      'addQuoteCta': '명언 추가',
      'quoteInputTitle': '내 문장 추가',
      'customQuotesHeader': '나의 라이브러리',
      'channelSettingsTitle': '전달 채널 설정',
      'preferencesHeader': '표시 환경 설정',
      'statusBarLabel': '상태바',
      'lockScreenLabel': '잠금화면',
      'homeWidgetLabel': '위젯',
      'refreshIntervalLabel': '갱신 주기',
      'minutesSuffix': '분',
      'refreshAction': '지금 새로고침',
      'feedbackHeader': '피드백 보내기',
      'feedbackHint': '의견을 알려주세요',
      'feedbackSubmitCta': '제출',
      'ratingLabel': '만족도 (1-5)',
      'emailHint': '이메일 (선택)',
      'emptyQuotesPlaceholder': '추가한 명언이 여기에 보여요.',
      'previewHeader': '미리보기',
      'surfaceDisabledHint': '위에서 활성화하면 미리보기가 제공돼요.',
      'quotePlaceholderHeadline': '새 명언을 불러오려면 새로고침을 눌러보세요.',
    },
    'ja': <String, String>{
      'appTitle': 'クォートコンパニオン',
      'brandSubtitle': 'LINEUPはインスピレーションを行動につなげます。',
      'quoteInputLabel': '名言',
      'authorInputLabel': '作者 (任意)',
      'addQuoteCta': '追加',
      'quoteInputTitle': 'マイフレーズを追加',
      'customQuotesHeader': 'マイライブラリ',
      'channelSettingsTitle': '配信チャネル設定',
      'preferencesHeader': '表示設定',
      'statusBarLabel': 'ステータスバー',
      'lockScreenLabel': 'ロックスクリーン',
      'homeWidgetLabel': 'ウィジェット',
      'refreshIntervalLabel': '更新間隔',
      'minutesSuffix': '分',
      'refreshAction': '今すぐ更新',
      'feedbackHeader': 'フィードバック',
      'feedbackHint': 'ご意見をお聞かせください',
      'feedbackSubmitCta': '送信',
      'ratingLabel': '満足度 (1-5)',
      'emailHint': 'メール (任意)',
      'emptyQuotesPlaceholder': 'ここに名言が表示されます。',
      'previewHeader': 'プレビュー',
      'surfaceDisabledHint': '上部で有効にするとプレビューできます。',
      'quotePlaceholderHeadline': '更新を押して新しい名言を読み込みましょう。',
    },
  };

  /// Supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
    Locale('ja'),
  ];

  /// Delegate for [AppLocalizations].
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Convenience lookup for widgets.
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('ko'));
  }

  /// Looks up a localized string.
  String translate(String key) {
    final Map<String, String>? localized =
        _localizedValues[locale.languageCode];
    return localized?[key] ?? _localizedValues['en']![key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((Locale item) => item.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}
