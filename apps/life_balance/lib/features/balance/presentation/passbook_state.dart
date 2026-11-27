import 'package:equatable/equatable.dart';

import '../domain/balance.dart';
import '../domain/calendar_date.dart';

class PassbookState extends Equatable {
  const PassbookState({
    required this.today,
    required this.birth,
    required this.maturity,
    required this.balance,
    required this.display,
    required this.usedRatio,
    required this.phrases,
  });

  final CalendarDate today;
  final CalendarDate birth;
  final CalendarDate maturity;
  final Balance balance;

  /// 설정 단위로 포맷된 잔고. 보너스면 `+` 접두.
  final String display;
  final double usedRatio;

  /// 화면용 PhraseKeys 키 -> 문장. 보너스면 withdrawal 대신 bonus_notice를 담는다.
  final Map<String, String> phrases;

  @override
  List<Object?> get props => [
    today,
    birth,
    maturity,
    balance,
    display,
    usedRatio,
    phrases,
  ];
}
