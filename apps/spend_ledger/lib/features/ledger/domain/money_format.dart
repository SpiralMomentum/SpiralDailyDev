import 'package:intl/intl.dart';

final NumberFormat _won = NumberFormat('#,###');

/// 금액을 `6,500원` 형식으로. 음수는 `-6,500원`.
String formatWon(int amount) => '${_won.format(amount)}원';
