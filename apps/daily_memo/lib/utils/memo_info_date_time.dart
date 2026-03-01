import 'package:intl/intl.dart';

class MemoInfoDateTime {
  final DateFormat dateFormat = DateFormat("yyyy-MM-dd");

  static DateTime? getFittedDateTime(DateTime? dateTime) {
    if (dateTime == null) return null;
    try {
      final DateTime result =
          DateTime.parse(DateFormat("yyyy-MM-dd").format(dateTime));
      return result;
    } catch (e) {
      return null;
    }
  }

  static DateTime? transferToDateTime(String? timeString) {
    if (timeString == null) return null;
    try {
      final DateTime result = DateFormat("yyyy-MM-dd").parse(timeString);

      return result;
    } catch (e) {
      return null;
    }
  }
}
