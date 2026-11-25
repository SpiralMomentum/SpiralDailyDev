import '../../balance/domain/balance.dart';
import '../../balance/domain/balance_format.dart';
import '../../balance/domain/calendar_date.dart';
import '../../tone/domain/phrase_keys.dart';
import '../../tone/domain/tone_table.dart';

/// 상시 알림 본문. 보너스면 `notification.bonus_body`의 `{bonus}`,
/// 아니면 `notification.body`의 `{balance}`를 설정 단위로 채운다.
String notificationText({
  required Balance balance,
  required BalanceUnit unit,
  required ToneTable tone,
  required CalendarDate today,
}) {
  final value = formatBalanceValue(balance, unit);
  return balance.isBonus
      ? fillPlaceholders(
          pickPhrase(tone, PhraseKeys.notificationBonusBody, today),
          {'bonus': value},
        )
      : fillPlaceholders(
          pickPhrase(tone, PhraseKeys.notificationBody, today),
          {'balance': value},
        );
}
