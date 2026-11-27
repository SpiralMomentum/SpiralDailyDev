import 'package:flutter_bloc/flutter_bloc.dart';

import '../../life_table/domain/life_table.dart';
import '../../profile/domain/settings.dart';
import '../../tone/domain/phrase_keys.dart';
import '../../tone/domain/tone_table.dart';
import '../domain/balance_calculator.dart';
import '../domain/balance_format.dart';
import '../domain/calendar_date.dart';
import '../domain/profile.dart';
import 'passbook_state.dart';

class PassbookCubit extends Cubit<PassbookState> {
  PassbookCubit({
    required Profile profile,
    required AppSettings settings,
    required LifeTable table,
    required ToneTable tone,
    required CalendarDate Function() today,
  }) : _profile = profile,
       _settings = settings,
       _table = table,
       _tone = tone,
       _today = today,
       super(_build(profile, settings, table, tone, today()));

  final Profile _profile;
  final AppSettings _settings;
  final LifeTable _table;
  final ToneTable _tone;
  final CalendarDate Function() _today;

  /// 앱이 resumed될 때 호출한다. 날짜가 바뀌면 새 값을 emit하고, 같으면 emit하지 않는다.
  void refresh() => emit(_build(_profile, _settings, _table, _tone, _today()));
}

PassbookState _build(
  Profile profile,
  AppSettings settings,
  LifeTable table,
  ToneTable tone,
  CalendarDate today,
) {
  final maturity = maturityDate(profile: profile, today: today, table: table);
  final balance = computeBalance(
    birth: profile.birthDate,
    maturity: maturity,
    today: today,
  );
  final display = formatBalanceValue(balance, settings.unit);
  String pick(String key) => pickPhrase(tone, key, today);
  return PassbookState(
    today: today,
    birth: profile.birthDate,
    maturity: maturity,
    balance: balance,
    display: display,
    usedRatio: usedRatio(balance),
    phrases: Map.unmodifiable({
      PhraseKeys.mainTitle: pick(PhraseKeys.mainTitle),
      PhraseKeys.mainBalanceLabel: pick(PhraseKeys.mainBalanceLabel),
      PhraseKeys.mainOpenedLabel: pick(PhraseKeys.mainOpenedLabel),
      PhraseKeys.mainMaturityLabel: pick(PhraseKeys.mainMaturityLabel),
      if (balance.isBonus)
        PhraseKeys.mainBonusNotice: fillPlaceholders(
          pick(PhraseKeys.mainBonusNotice),
          {'bonus': display},
        )
      else
        PhraseKeys.mainWithdrawal: pick(PhraseKeys.mainWithdrawal),
    }),
  );
}
