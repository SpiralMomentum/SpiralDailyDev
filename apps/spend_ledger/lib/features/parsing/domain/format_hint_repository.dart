import 'format_hint.dart';

abstract interface class FormatHintRepository {
  Future<FormatHint?> get(String signature);
  Future<void> put(FormatHint hint);
}
