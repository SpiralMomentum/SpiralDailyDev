// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Daily Memo';

  @override
  String get memoListTitle => 'Memo List';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get newMemo => 'New Memo';

  @override
  String get saveMemo => 'Save';

  @override
  String get deleteMemo => 'Delete';

  @override
  String get deleteAction => 'Delete';

  @override
  String get deleteConfirmation => 'Are you sure you want to delete this memo?';

  @override
  String get noMemos => 'No memos yet.';

  @override
  String get memoTitleHint => 'Enter title';

  @override
  String get memoContentHint => 'Enter content';

  @override
  String get titleLabel => 'Title';

  @override
  String get contentLabel => 'Content';

  @override
  String get emptyTitle => '(Empty title)';

  @override
  String get emptyContent => '(Empty content)';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'OK';

  @override
  String get home => 'Home';

  @override
  String get notifications => 'Notifications';

  @override
  String modifiedDate(String date) {
    return 'Modified $date';
  }

  @override
  String createdDate(String date) {
    return 'Created $date';
  }
}
