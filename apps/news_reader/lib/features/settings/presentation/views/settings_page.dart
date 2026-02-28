import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:apps.news_reader/features/news_feed/domain/entities/article.dart';
import '../../domain/entities/user_preferences.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state.status == SettingsStatus.loading ||
              state.status == SettingsStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == SettingsStatus.error) {
            return Center(
              child: Text(state.errorMessage ?? 'An error occurred'),
            );
          }

          final prefs = state.preferences;
          return ListView(
            children: [
              _buildSectionHeader(context, 'Appearance'),
              _buildThemeTile(context, prefs),
              const Divider(height: 1),
              _buildSectionHeader(context, 'Language'),
              _buildLocaleTile(context, prefs),
              const Divider(height: 1),
              _buildSectionHeader(context, 'Notifications'),
              _buildNotificationTile(context, prefs),
              const Divider(height: 1),
              _buildSectionHeader(context, 'Preferred Categories'),
              _buildCategoryChips(context, prefs),
              const Divider(height: 1),
              _buildVersionInfo(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context, UserPreferences prefs) {
    return ListTile(
      title: const Text('Theme'),
      trailing: DropdownButton<ThemeMode>(
        value: prefs.themeMode,
        underline: const SizedBox.shrink(),
        onChanged: (mode) {
          if (mode != null) {
            context.read<SettingsCubit>().changeTheme(mode);
          }
        },
        items: const [
          DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
          DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
          DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
        ],
      ),
    );
  }

  Widget _buildLocaleTile(BuildContext context, UserPreferences prefs) {
    return ListTile(
      title: const Text('Language'),
      trailing: DropdownButton<AppLocale>(
        value: prefs.locale,
        underline: const SizedBox.shrink(),
        onChanged: (locale) {
          if (locale != null) {
            context.read<SettingsCubit>().changeLocale(locale);
          }
        },
        items: const [
          DropdownMenuItem(
            value: AppLocale.ko,
            child: Text('\ud55c\uad6d\uc5b4'),
          ),
          DropdownMenuItem(
            value: AppLocale.en,
            child: Text('English'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, UserPreferences prefs) {
    return SwitchListTile(
      title: const Text('Enable Notifications'),
      value: prefs.notificationsEnabled,
      onChanged: (value) {
        context.read<SettingsCubit>().toggleNotifications(value);
      },
    );
  }

  Widget _buildCategoryChips(BuildContext context, UserPreferences prefs) {
    final allCategories = ArticleCategory.values
        .where((c) => c != ArticleCategory.unknown)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: allCategories.map((category) {
          final isSelected = prefs.preferredCategories.contains(category.name);
          return FilterChip(
            label: Text(category.name),
            selected: isSelected,
            onSelected: (selected) {
              final current = List<String>.from(prefs.preferredCategories);
              if (selected) {
                current.add(category.name);
              } else {
                current.remove(category.name);
              }
              context.read<SettingsCubit>().updateCategories(current);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVersionInfo(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Text(
          'News Reader v1.0.0',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
