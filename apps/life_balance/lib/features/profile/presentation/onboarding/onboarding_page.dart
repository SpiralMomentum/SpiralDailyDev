import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../balance/domain/balance_format.dart';
import '../../../balance/domain/calendar_date.dart';
import '../../../balance/domain/profile.dart';
import '../../../life_table/data/life_table_parser.dart';
import '../../../tone/domain/phrase_keys.dart';
import '../../../tone/domain/tone.dart';
import '../../../tone/domain/tone_table.dart';
import '../../../tone/presentation/tone_theme.dart';
import 'onboarding_cubit.dart';
import 'onboarding_state.dart';
import 'widget_pinner.dart';

const _stepTitles = {
  OnboardingStep.birthDate: '생년월일',
  OnboardingStep.sex: '생명표 기준 성별',
  OnboardingStep.country: '국가',
  OnboardingStep.lifespan: '기대수명',
  OnboardingStep.tone: '말투',
};

const _toneLabels = {
  ToneId.stoic: '절제된 스토아',
  ToneId.wit: '재치 있는 농담',
  ToneId.community: '커뮤니티 말투',
};

const _errorTexts = {
  OnboardingError.futureBirthDate: '오늘 이후의 날짜는 선택할 수 없습니다.',
  OnboardingError.invalidLifespan: '0보다 크고 150 이하인 숫자를 입력하세요.',
  OnboardingError.saveFailed: '저장하지 못했습니다. 다시 시도하세요.',
};

/// 온보딩 화면. [cubit]의 수명 주기는 호출한 쪽이 관리한다.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.cubit,
    required this.countries,
    required this.tones,
    required this.today,
    this.pinner = const HomeWidgetPinner(),
  });

  final OnboardingCubit cubit;
  final List<CountryInfo> countries;
  final Map<ToneId, ToneTable> tones;
  final CalendarDate Function() today;
  final WidgetPinner pinner;

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<OnboardingCubit, OnboardingState>(
        builder: (context, state) => Theme(
          data: themeFor(state.tone, brightness),
          child: Builder(
            builder: (context) => Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: state.step == OnboardingStep.done
                      ? _DoneView(
                          state: state,
                          tones: tones,
                          today: today,
                          pinner: pinner,
                        )
                      : _StepView(
                          state: state,
                          countries: countries,
                          tones: tones,
                          today: today,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String? _phrase(
  Map<ToneId, ToneTable> tones,
  ToneId tone,
  String key,
  CalendarDate today,
) {
  final table = tones[tone];
  return table == null ? null : pickPhrase(table, key, today);
}

class _StepView extends StatelessWidget {
  const _StepView({
    required this.state,
    required this.countries,
    required this.tones,
    required this.today,
  });

  final OnboardingState state;
  final List<CountryInfo> countries;
  final Map<ToneId, ToneTable> tones;
  final CalendarDate Function() today;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final theme = Theme.of(context);
    final step = state.step;
    final isFirst = step == OnboardingStep.birthDate;
    final isLast = step == OnboardingStep.tone;
    final canNext =
        !state.saving &&
        state.error != OnboardingError.invalidLifespan &&
        (step != OnboardingStep.birthDate || state.birthDate != null);
    final intro = isFirst
        ? _phrase(tones, state.tone, PhraseKeys.onboardingIntro, today())
        : null;
    final error = state.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${step.index + 1} / ${_stepTitles.length}',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (step.index + 1) / _stepTitles.length,
          color: theme.colorScheme.onSurface,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
        ),
        const SizedBox(height: 24),
        if (intro != null) ...[
          Text(intro, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
        ],
        Text(_stepTitles[step]!, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        Expanded(child: _stepBody(context, cubit)),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _errorTexts[error]!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        Row(
          children: [
            if (!isFirst)
              TextButton(
                onPressed: cubit.back,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                ),
                child: const Text('이전'),
              ),
            const Spacer(),
            FilledButton(
              onPressed: canNext
                  ? (isLast ? cubit.complete : cubit.next)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.onSurface,
                foregroundColor: theme.colorScheme.surface,
              ),
              child: Text(isLast ? '시작하기' : '다음'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stepBody(BuildContext context, OnboardingCubit cubit) {
    switch (state.step) {
      case OnboardingStep.birthDate:
        return _BirthDateBody(state: state, today: today, cubit: cubit);
      case OnboardingStep.sex:
        return Column(
          children: [
            _Option(
              label: '남성',
              selected: state.sex == Sex.male,
              onTap: () => cubit.setSex(Sex.male),
            ),
            _Option(
              label: '여성',
              selected: state.sex == Sex.female,
              onTap: () => cubit.setSex(Sex.female),
            ),
          ],
        );
      case OnboardingStep.country:
        return ListView(
          children: [
            for (final c in countries)
              _Option(
                label: c.name,
                selected: c.code == state.countryCode,
                onTap: () => cubit.setCountry(c.code),
              ),
          ],
        );
      case OnboardingStep.lifespan:
        return _LifespanBody(
          state: state,
          cubit: cubit,
          source: countries
              .where((c) => c.code == state.countryCode)
              .map((c) => '${c.sourceName} ${c.sourceYear}')
              .firstOrNull,
        );
      case OnboardingStep.tone:
        return Column(
          children: [
            for (final t in ToneId.values)
              _Option(
                label: _toneLabels[t]!,
                selected: t == state.tone,
                onTap: () => cubit.setTone(t),
              ),
          ],
        );
      case OnboardingStep.done:
        return const SizedBox.shrink();
    }
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? scheme.onSurface : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Expanded(child: Text(label)),
                if (selected) const Icon(Icons.check),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BirthDateBody extends StatelessWidget {
  const _BirthDateBody({
    required this.state,
    required this.today,
    required this.cubit,
  });

  final OnboardingState state;
  final CalendarDate Function() today;
  final OnboardingCubit cubit;

  Future<void> _pick(BuildContext context) async {
    final now = today();
    final birth = state.birthDate;
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDate: birth == null
          ? DateTime(now.year - 30, now.month, now.day)
          : DateTime(birth.year, birth.month, birth.day),
    );
    if (picked != null) cubit.setBirthDate(CalendarDate.fromDateTime(picked));
  }

  @override
  Widget build(BuildContext context) {
    final birth = state.birthDate;
    return Align(
      alignment: Alignment.topLeft,
      child: OutlinedButton(
        onPressed: () => _pick(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          minimumSize: const Size(0, 56),
        ),
        child: Text(
          birth == null
              ? '생년월일 선택'
              : '${birth.year}년 ${birth.month}월 ${birth.day}일',
        ),
      ),
    );
  }
}

class _LifespanBody extends StatefulWidget {
  const _LifespanBody({
    required this.state,
    required this.cubit,
    required this.source,
  });

  final OnboardingState state;
  final OnboardingCubit cubit;
  final String? source;

  @override
  State<_LifespanBody> createState() => _LifespanBodyState();
}

class _LifespanBodyState extends State<_LifespanBody> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.state.manualLifespanYears?.toString() ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estimate = widget.state.estimatedLifespanYears;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (estimate != null)
          Text(
            '생명표 추정 기대수명 ${estimate.toStringAsFixed(1)}세',
            style: theme.textTheme.titleMedium,
          ),
        if (widget.source != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '출처 ${widget.source}',
              style: theme.textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: '직접 입력(세, 비워 두면 추정값 사용)',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) {
            final text = v.trim();
            widget.cubit.setManualLifespan(
              text.isEmpty ? null : (double.tryParse(text) ?? double.nan),
            );
          },
        ),
      ],
    );
  }
}

class _DoneView extends StatefulWidget {
  const _DoneView({
    required this.state,
    required this.tones,
    required this.today,
    required this.pinner,
  });

  final OnboardingState state;
  final Map<ToneId, ToneTable> tones;
  final CalendarDate Function() today;
  final WidgetPinner pinner;

  @override
  State<_DoneView> createState() => _DoneViewState();
}

class _DoneViewState extends State<_DoneView> {
  late final Future<bool> _pinSupported = widget.pinner.isSupported();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balance = widget.state.firstBalance;
    final guide = _phrase(
      widget.tones,
      widget.state.tone,
      PhraseKeys.onboardingWidgetGuide,
      widget.today(),
    );
    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: theme.colorScheme.onSurface,
      foregroundColor: theme.colorScheme.surface,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Text(
          '첫 잔고',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (balance != null)
          Text(
            formatBalanceValue(balance, BalanceUnit.days),
            textAlign: TextAlign.center,
            style: theme.textTheme.displayLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        const Spacer(),
        FutureBuilder<bool>(
          future: _pinSupported,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SizedBox.shrink();
            }
            if (snap.data == true) {
              return FilledButton(
                onPressed: widget.pinner.requestPin,
                style: buttonStyle,
                child: const Text('홈 화면에 위젯 추가'),
              );
            }
            return guide == null ? const SizedBox.shrink() : Text(guide);
          },
        ),
        const SizedBox(height: 12),
        if (widget.state.notificationGranted == false)
          const Text(
            '알림 권한이 없어 상시 알림을 껐습니다. 설정에서 켤 수 있습니다.',
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}
