import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../balance/domain/balance_format.dart';
import '../../balance/domain/calendar_date.dart';
import '../../balance/domain/profile.dart';
import '../../life_table/data/life_table_parser.dart';
import '../../profile/domain/settings.dart';
import '../../profile/presentation/onboarding/widget_pinner.dart';
import '../../tone/domain/phrase_keys.dart';
import '../../tone/domain/tone.dart';
import '../../tone/domain/tone_table.dart';
import '../../tone/presentation/tone_theme.dart';
import 'settings_cubit.dart';

const _unitLabels = {
  BalanceUnit.days: '일',
  BalanceUnit.weeks: '주',
  BalanceUnit.years: '년',
  BalanceUnit.percent: '퍼센트',
};

const _toneLabels = {
  ToneId.stoic: '절제된 스토아',
  ToneId.wit: '재치 있는 농담',
  ToneId.community: '커뮤니티 말투',
};

const _themeLabels = {
  ThemePref.system: '시스템',
  ThemePref.light: '라이트',
  ThemePref.dark: '다크',
};

const _errorTexts = {
  SettingsError.futureBirthDate: '오늘 이후의 날짜는 선택할 수 없습니다.',
  SettingsError.invalidLifespan: '0보다 크고 150 이하인 숫자를 입력하세요.',
  SettingsError.saveFailed: '저장하지 못했습니다. 다시 시도하세요.',
};

/// 설정 화면. [cubit]의 수명 주기는 호출한 쪽이 관리한다.
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.cubit,
    required this.countries,
    required this.tones,
    required this.today,
    this.pinner = const HomeWidgetPinner(),
  });

  final SettingsCubit cubit;
  final List<CountryInfo> countries;
  final Map<ToneId, ToneTable> tones;
  final CalendarDate Function() today;
  final WidgetPinner pinner;

  Brightness _brightness(BuildContext context, ThemePref pref) =>
      switch (pref) {
        ThemePref.light => Brightness.light,
        ThemePref.dark => Brightness.dark,
        ThemePref.system => MediaQuery.platformBrightnessOf(context),
      };

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          final brightness = _brightness(context, state.settings.themePref);
          return Theme(
            data: themeFor(state.settings.tone, brightness),
            child: Builder(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: const Text('설정'),
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                ),
                body: SafeArea(
                  child: _Body(
                    state: state,
                    countries: countries,
                    tones: tones,
                    today: today,
                    pinner: pinner,
                    brightness: brightness,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.countries,
    required this.tones,
    required this.today,
    required this.pinner,
    required this.brightness,
  });

  final SettingsState state;
  final List<CountryInfo> countries;
  final Map<ToneId, ToneTable> tones;
  final CalendarDate Function() today;
  final WidgetPinner pinner;
  final Brightness brightness;

  Future<void> _pickBirth(BuildContext context, SettingsCubit cubit) async {
    final now = today();
    final birth = state.profile.birthDate;
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDate: DateTime(birth.year, birth.month, birth.day),
    );
    if (picked != null) {
      await cubit.updateProfile(
        state.profile.copyWith(birthDate: CalendarDate.fromDateTime(picked)),
      );
    }
  }

  Future<void> _showGuide(BuildContext context) async {
    if (await pinner.isSupported()) {
      await pinner.requestPin();
      return;
    }
    final table = tones[state.settings.tone];
    final guide = table == null
        ? null
        : pickPhrase(table, PhraseKeys.onboardingWidgetGuide, today());
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(guide ?? '홈 화면을 길게 눌러 위젯을 추가하세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    final theme = Theme.of(context);
    final profile = state.profile;
    final settings = state.settings;
    final error = state.error;
    final birth = profile.birthDate;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _errorTexts[error]!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        const _Section('내 정보'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('생년월일'),
          subtitle: Text('${birth.year}년 ${birth.month}월 ${birth.day}일'),
          onTap: () => _pickBirth(context, cubit),
        ),
        const Text('생명표 기준 성별'),
        const SizedBox(height: 8),
        _Choices<Sex>(
          values: Sex.values,
          selected: profile.sex,
          label: (s) => s == Sex.male ? '남성' : '여성',
          onSelected: (s) => cubit.updateProfile(profile.copyWith(sex: s)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: Text('국가')),
            DropdownButton<String>(
              value: countries.any((c) => c.code == profile.countryCode)
                  ? profile.countryCode
                  : null,
              onChanged: (code) {
                if (code != null) {
                  cubit.updateProfile(profile.copyWith(countryCode: code));
                }
              },
              items: [
                for (final c in countries)
                  DropdownMenuItem(value: c.code, child: Text(c.name)),
              ],
            ),
          ],
        ),
        _LifespanSection(profile: profile, cubit: cubit),
        const SizedBox(height: 24),
        const _Section('표시'),
        const Text('표시 단위'),
        const SizedBox(height: 8),
        _Choices<BalanceUnit>(
          values: BalanceUnit.values,
          selected: settings.unit,
          label: (u) => _unitLabels[u]!,
          onSelected: cubit.setUnit,
        ),
        const SizedBox(height: 16),
        const Text('말투'),
        const SizedBox(height: 8),
        _Choices<ToneId>(
          values: ToneId.values,
          selected: settings.tone,
          label: (t) => _toneLabels[t]!,
          // 말투별 포인트 색은 장식 요소(점)에만 쓴다. 글자색에는 쓰지 않는다.
          leading: (t) => Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: paletteFor(t, brightness).accent,
              shape: BoxShape.circle,
            ),
          ),
          onSelected: cubit.setTone,
        ),
        const SizedBox(height: 16),
        const Text('화면 모드'),
        const SizedBox(height: 8),
        _Choices<ThemePref>(
          values: ThemePref.values,
          selected: settings.themePref,
          label: (p) => _themeLabels[p]!,
          onSelected: cubit.setThemePref,
        ),
        const SizedBox(height: 24),
        const _Section('알림과 위젯'),
        SwitchListTile(
          key: const Key('ongoing-switch'),
          contentPadding: EdgeInsets.zero,
          title: const Text('상시 알림'),
          value: settings.ongoingNotification,
          onChanged: cubit.setOngoing,
        ),
        if (state.permissionDenied)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('알림 권한이 없어 켤 수 없습니다. 기기 설정에서 알림 권한을 허용하세요.'),
          ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('위젯 추가 안내 다시 보기'),
          onTap: () => _showGuide(context),
        ),
        const SizedBox(height: 24),
        const _Section('데이터 출처'),
        for (final c in countries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('${c.name}: ${c.sourceName} ${c.sourceYear}'),
          ),
        const SizedBox(height: 24),
        const _Section('라이선스'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('오픈소스 라이선스'),
          onTap: () => showLicensePage(context: context),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: Theme.of(context).textTheme.titleLarge),
  );
}

class _Choices<T> extends StatelessWidget {
  const _Choices({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
    this.leading,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final void Function(T) onSelected;
  final Widget Function(T)? leading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          ChoiceChip(
            avatar: leading?.call(v),
            label: Text(label(v)),
            selected: v == selected,
            showCheckmark: false,
            selectedColor: scheme.surfaceContainerHighest,
            side: BorderSide(
              color: v == selected ? scheme.onSurface : scheme.outlineVariant,
              width: v == selected ? 2 : 1,
            ),
            onSelected: (_) => onSelected(v),
          ),
      ],
    );
  }
}

class _LifespanSection extends StatefulWidget {
  const _LifespanSection({required this.profile, required this.cubit});

  final Profile profile;
  final SettingsCubit cubit;

  @override
  State<_LifespanSection> createState() => _LifespanSectionState();
}

class _LifespanSectionState extends State<_LifespanSection> {
  late bool _manual = widget.profile.manualLifespanYears != null;
  late final TextEditingController _controller = TextEditingController(
    text: widget.profile.manualLifespanYears?.toString() ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle(bool manual) {
    setState(() => _manual = manual);
    if (!manual) {
      _controller.clear();
      widget.cubit.setManualLifespan(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          key: const Key('lifespan-manual-switch'),
          contentPadding: EdgeInsets.zero,
          title: const Text('기대수명 직접 입력'),
          subtitle: Text(_manual ? '입력한 값을 사용합니다' : '생명표 추정값을 사용합니다'),
          value: _manual,
          onChanged: _toggle,
        ),
        if (_manual)
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: '기대수명(세)',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              final text = v.trim();
              if (text.isEmpty) return;
              widget.cubit.setManualLifespan(
                double.tryParse(text) ?? double.nan,
              );
            },
          ),
      ],
    );
  }
}
