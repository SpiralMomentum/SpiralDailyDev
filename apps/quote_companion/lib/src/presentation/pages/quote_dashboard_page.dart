import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_components/ui_components.dart';

import '../../domain/entities/quote_display_preferences.dart';
import '../l10n/app_localizations.dart';
import '../state/quote_notifier.dart';
import '../state/quote_state.dart';
import '../widgets/quote_card.dart';
import '../widgets/quote_surface_previews.dart';

/// Home screen showcasing inspirational quotes and controls.
class QuoteDashboardPage extends ConsumerStatefulWidget {
  /// Creates [QuoteDashboardPage].
  const QuoteDashboardPage({super.key});

  @override
  ConsumerState<QuoteDashboardPage> createState() =>
      _QuoteDashboardPageState();
}

class _QuoteDashboardPageState extends ConsumerState<QuoteDashboardPage> {
  final TextEditingController _quoteController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _quoteController.dispose();
    _authorController.dispose();
    _feedbackController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final QuoteState state = ref.watch(quoteNotifierProvider);
    final QuoteNotifier notifier = ref.read(quoteNotifierProvider.notifier);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    final double refreshMinutes =
        state.preferences.refreshInterval.inMinutes.toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('appTitle')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: <Widget>[
            if (state.activeQuote != null)
              DetailCard(
                sectionTitle: l10n.translate('appTitle'),
                primaryColor: theme.colorScheme.primaryContainer,
                info: Info(
                  state.activeQuote!.author.isEmpty
                      ? l10n.translate('appTitle')
                      : state.activeQuote!.author,
                  'https://picsum.photos/seed/${state.activeQuote!.id}/200/270',
                  l10n.translate('preferencesHeader'),
                  state.activeQuote!.text,
                  DateTime.now(),
                  DateTime.now().add(state.preferences.refreshInterval),
                ),
              )
            else if (state.isLoading)
              const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ElevatedButton.icon(
                  onPressed: notifier.refreshQuote,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.translate('refreshIntervalLabel')),
                ),
                if (state.errorMessage != null)
                  Chip(
                    label: Text(
                      state.errorMessage!,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onError),
                    ),
                    backgroundColor: theme.colorScheme.errorContainer,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              l10n.translate('quoteInputLabel'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _quoteController,
              maxLines: 2,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: l10n.translate('quoteInputLabel'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _authorController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: l10n.translate('authorInputLabel'),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () async {
                  final String text = _quoteController.text.trim();
                  if (text.isEmpty) {
                    return;
                  }
                  await notifier.addQuote(
                    text: text,
                    author: _authorController.text.trim(),
                  );
                  _quoteController.clear();
                  _authorController.clear();
                },
                child: Text(l10n.translate('addQuoteCta')),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.translate('customQuotesHeader'),
              style: theme.textTheme.titleMedium,
            ),
            if (state.customQuotes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(l10n.translate('emptyQuotesPlaceholder')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (BuildContext context, int index) {
                  final quote = state.customQuotes[index];
                  return Dismissible(
                    key: ValueKey<String>(quote.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => notifier.removeQuote(quote.id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      color: theme.colorScheme.error,
                      child: Icon(
                        Icons.delete,
                        color: theme.colorScheme.onError,
                      ),
                    ),
                    child: QuoteCard(quote: quote),
                  );
                },
                separatorBuilder: (_, __) => const Divider(),
                itemCount: state.customQuotes.length,
              ),
            const SizedBox(height: 24),
            Text(
              l10n.translate('preferencesHeader'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _TargetToggle(
              title: l10n.translate('statusBarLabel'),
              isActive: state.preferences
                  .isTargetEnabled(QuoteDisplayTarget.statusBar),
              onChanged: () =>
                  notifier.toggleTarget(QuoteDisplayTarget.statusBar),
            ),
            _TargetToggle(
              title: l10n.translate('lockScreenLabel'),
              isActive: state.preferences
                  .isTargetEnabled(QuoteDisplayTarget.lockScreen),
              onChanged: () =>
                  notifier.toggleTarget(QuoteDisplayTarget.lockScreen),
            ),
            _TargetToggle(
              title: l10n.translate('homeWidgetLabel'),
              isActive: state.preferences
                  .isTargetEnabled(QuoteDisplayTarget.homeWidget),
              onChanged: () =>
                  notifier.toggleTarget(QuoteDisplayTarget.homeWidget),
            ),
            const SizedBox(height: 12),
            Text(
              '${l10n.translate('refreshIntervalLabel')}: ${refreshMinutes.toInt()} ${l10n.translate('minutesSuffix')}',
            ),
            Slider(
              value: refreshMinutes,
              min: 30,
              max: 720,
              divisions: 23,
              label: refreshMinutes.toInt().toString(),
              onChanged: (double value) async {
                await notifier.updateRefreshInterval(value.toInt());
              },
            ),
            if (state.activeQuote != null) ...<Widget>[
              const SizedBox(height: 24),
              QuoteSurfacePreviews(
                quote: state.activeQuote!,
                preferences: state.preferences,
              ),
            ],
            const SizedBox(height: 24),
            Text(
              l10n.translate('feedbackHeader'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _feedbackController,
              maxLines: 3,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: l10n.translate('feedbackHint'),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: l10n.translate('emailHint'),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: _rating,
                  onChanged: (int? value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _rating = value;
                    });
                  },
                  items: List<DropdownMenuItem<int>>.generate(5, (int index) {
                    final int value = index + 1;
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value'),
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () async {
                  if (_feedbackController.text.trim().isEmpty) {
                    return;
                  }
                  await notifier.submitFeedback(
                    message: _feedbackController.text.trim(),
                    rating: _rating,
                    contactEmail: _emailController.text.trim().isEmpty
                        ? null
                        : _emailController.text.trim(),
                  );
                  _feedbackController.clear();
                  _emailController.clear();
                  setState(() {
                    _rating = 5;
                  });
                },
                child: Text(l10n.translate('feedbackSubmitCta')),
              ),
            ),
            const SizedBox(height: 24),
            if (state.feedbackHistory.isNotEmpty)
              ExpansionTile(
                title: Text(l10n.translate('feedbackHeader')),
                children: state.feedbackHistory
                    .map((feedback) => ListTile(
                          title: Text(feedback.message),
                          subtitle: Text(
                            '${feedback.rating}/5 • ${feedback.createdAt.toLocal()}',
                          ),
                        ))
                    .toList(),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _TargetToggle extends StatelessWidget {
  const _TargetToggle({
    required this.title,
    required this.isActive,
    required this.onChanged,
  });

  final String title;
  final bool isActive;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: theme.textTheme.bodyLarge),
      value: isActive,
      onChanged: (_) => onChanged(),
    );
  }
}
