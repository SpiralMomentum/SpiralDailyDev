import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/domain/palette.dart';
import 'settings_cubit.dart';
import 'settings_load_error.dart';

/// 밝기 선택지의 화면 문구.
String themeModeLabel(AppThemeMode mode) => switch (mode) {
  AppThemeMode.system => '시스템',
  AppThemeMode.light => '밝게',
  AppThemeMode.dark => '어둡게',
};

class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('테마')),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (!state.loaded) {
            return state.loading
                ? const Center(child: CircularProgressIndicator())
                : const SettingsLoadError();
          }
          final s = state.settings;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final id in AppThemeId.values)
                _ThemeCard(
                  id: id,
                  palette: dark ? themeColors(id).dark : themeColors(id).light,
                  selected: id == s.themeId,
                  onTap: () => cubit.setTheme(id),
                ),
              const SizedBox(height: 16),
              SegmentedButton<AppThemeMode>(
                segments: [
                  for (final m in AppThemeMode.values)
                    ButtonSegment(value: m, label: Text(themeModeLabel(m))),
                ],
                selected: {s.themeMode},
                onSelectionChanged: (v) => cubit.setThemeMode(v.first),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.id,
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final AppThemeId id;
  final Palette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  id.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _Swatch(palette.background, outlined: true),
              _Swatch(palette.primary),
              _Swatch(palette.warning),
              SizedBox(
                width: 32,
                child: selected
                    ? Icon(Icons.check, color: scheme.primary)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.argb, {this.outlined = false});

  final int argb;
  final bool outlined;

  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    margin: const EdgeInsets.only(left: 8),
    decoration: BoxDecoration(
      color: Color(argb),
      shape: BoxShape.circle,
      border: outlined
          ? Border.all(color: Theme.of(context).colorScheme.outlineVariant)
          : null,
    ),
  );
}
