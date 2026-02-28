import 'package:flutter/services.dart';

class HapticService {
  const HapticService._();

  static void lightImpact() => HapticFeedback.lightImpact();

  static void mediumImpact() => HapticFeedback.mediumImpact();

  static void heavyImpact() => HapticFeedback.heavyImpact();

  static void selectionClick() => HapticFeedback.selectionClick();

  static void bookmarkToggle() => HapticFeedback.mediumImpact();

  static void commentPosted() => HapticFeedback.mediumImpact();

  static void pullToRefresh() => HapticFeedback.lightImpact();
}
