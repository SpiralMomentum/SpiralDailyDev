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
  String get errorNetwork => 'Network error. Please check your connection.';

  @override
  String get errorServer => 'Server error. Please try again later.';

  @override
  String get errorUnknown => 'An unexpected error occurred.';

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
}
