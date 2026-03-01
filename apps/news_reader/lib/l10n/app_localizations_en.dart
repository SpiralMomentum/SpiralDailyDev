// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'News Reader';

  @override
  String get feedTitle => 'Feed';

  @override
  String get bookmarksTitle => 'Bookmarks';

  @override
  String get searchTitle => 'Search';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get commentsTitle => 'Comments';

  @override
  String get onboardingTitle => 'Get Started';

  @override
  String get errorNetwork => 'Network error. Please check your connection.';

  @override
  String get errorServer => 'Server error. Please try again later.';

  @override
  String get errorUnknown => 'An unexpected error occurred.';

  @override
  String get errorLocalStorage => 'Local storage error occurred.';

  @override
  String get retry => 'Retry';

  @override
  String get emptyFeed => 'No articles found.';

  @override
  String get emptyBookmarks => 'No saved articles.';

  @override
  String get emptySearch => 'No search results.';

  @override
  String get emptyComments => 'Be the first to comment!';

  @override
  String get bookmarkAdded => 'Article bookmarked.';

  @override
  String get bookmarkRemoved => 'Bookmark removed.';

  @override
  String get searchHint => 'Search articles...';

  @override
  String get commentHint => 'Write a comment...';

  @override
  String get commentSend => 'Send';

  @override
  String get commentReply => 'Reply';

  @override
  String commentCount(int count) {
    return '$count comments';
  }

  @override
  String get articleDetail => 'Article Detail';

  @override
  String get share => 'Share';

  @override
  String get categoryTechnology => 'Technology';

  @override
  String get categoryBusiness => 'Business';

  @override
  String get categoryScience => 'Science';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categorySports => 'Sports';

  @override
  String get categoryEntertainment => 'Entertainment';

  @override
  String get categoryGeneral => 'General';

  @override
  String get categoryAll => 'All';

  @override
  String get onboardingIntroTitle => 'Welcome to News Reader';

  @override
  String get onboardingIntroDescription =>
      'Discover news, bookmark articles, and join the conversation.';

  @override
  String get onboardingCategoryTitle => 'Choose your interests';

  @override
  String get onboardingCategoryDescription => 'Select at least 3 categories.';

  @override
  String get onboardingNotificationTitle => 'Enable notifications?';

  @override
  String get onboardingNotificationDescription =>
      'Get notified about new articles and comments.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get Started';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsCategories => 'Preferred Categories';

  @override
  String get settingsVersion => 'Version';

  @override
  String get searchHistory => 'Recent Searches';

  @override
  String get searchClear => 'Clear History';

  @override
  String get syncPending => 'Sync pending';

  @override
  String get syncComplete => 'Sync complete';

  @override
  String get forcedUpdateTitle => 'Update Required';

  @override
  String get forcedUpdateMessage => 'Please update to the latest version.';

  @override
  String get forcedUpdateButton => 'Update';
}
