import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/quote.dart';
import '../../domain/entities/quote_display_preferences.dart';
import '../l10n/app_localizations.dart';
import '../state/quote_notifier.dart';
import '../state/quote_state.dart';

/// Home screen showcasing inspirational quotes and controls styled for LINEUP.
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

  @override
  void dispose() {
    _quoteController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final QuoteState state = ref.watch(quoteNotifierProvider);
    final QuoteNotifier notifier = ref.read(quoteNotifierProvider.notifier);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    final Quote? activeQuote = state.activeQuote;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFF0C4FD9),
              Color(0xFF4D9EFF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _BrandHeader(
                  subtitle: l10n.translate('brandSubtitle'),
                  onRefresh: notifier.refreshQuote,
                ),
                const SizedBox(height: 32),
                _QuoteHighlight(
                  quote: activeQuote,
                  placeholder: l10n.translate('quotePlaceholderHeadline'),
                  fallbackAuthor: l10n.translate('appTitle'),
                ),
                if (state.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                if (state.errorMessage != null) ...<Widget>[
                  const SizedBox(height: 16),
                  _ErrorBanner(message: state.errorMessage!),
                ],
                const SizedBox(height: 32),
                _buildQuoteInputCard(theme, l10n, notifier),
                const SizedBox(height: 16),
                _buildLibraryCard(theme, l10n, state, notifier),
                const SizedBox(height: 16),
                _buildDeliveryPreferencesCard(
                  theme,
                  l10n,
                  notifier,
                  state.displayPreferences,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteInputCard(
    ThemeData theme,
    AppLocalizations l10n,
    QuoteNotifier notifier,
  ) {
    return Container(
      decoration: _glassCardDecoration(context),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.translate('quoteInputTitle'),
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _quoteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: l10n.translate('quoteInputLabel'),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _authorController,
            decoration: InputDecoration(
              hintText: l10n.translate('authorInputLabel'),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
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
        ],
      ),
    );
  }

  Widget _buildLibraryCard(
    ThemeData theme,
    AppLocalizations l10n,
    QuoteState state,
    QuoteNotifier notifier,
  ) {
    return Container(
      decoration: _glassCardDecoration(context),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.translate('customQuotesHeader'),
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (state.customQuotes.isEmpty)
            Text(
              l10n.translate('emptyQuotesPlaceholder'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.72),
              ),
            )
          else
            Column(
              children: <Widget>[
                for (int index = 0;
                    index < state.customQuotes.length;
                    index++)
                  _DismissibleQuoteTile(
                    quote: state.customQuotes[index],
                    onDismissed: () =>
                        notifier.removeQuote(state.customQuotes[index].id),
                    isLast: index == state.customQuotes.length - 1,
                    fallbackAuthor: l10n.translate('appTitle'),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDeliveryPreferencesCard(
    ThemeData theme,
    AppLocalizations l10n,
    QuoteNotifier notifier,
    QuoteDisplayPreferences preferences,
  ) {
    return Container(
      decoration: _glassCardDecoration(context),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.translate('deliverySurfacesTitle'),
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.translate('deliverySurfacesDescription'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.72),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          _SurfaceToggleTile(
            label: l10n.translate('statusBarLabel'),
            value: preferences.statusBarEnabled,
            onChanged: (bool value) =>
                notifier.updateDeliveryPreferences(statusBarEnabled: value),
          ),
          const SizedBox(height: 12),
          _SurfaceToggleTile(
            label: l10n.translate('lockScreenLabel'),
            value: preferences.lockScreenEnabled,
            onChanged: (bool value) =>
                notifier.updateDeliveryPreferences(lockScreenEnabled: value),
          ),
          const SizedBox(height: 12),
          _SurfaceToggleTile(
            label: l10n.translate('homeWidgetLabel'),
            value: preferences.homeWidgetEnabled,
            onChanged: (bool value) =>
                notifier.updateDeliveryPreferences(homeWidgetEnabled: value),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: notifier.refreshQuote,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(l10n.translate('refreshAction')),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _glassCardDecoration(BuildContext context) {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white.withOpacity(0.2)),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 40,
          offset: Offset(0, 20),
        ),
      ],
    );
  }

}

class _SurfaceToggleTile extends StatelessWidget {
  const _SurfaceToggleTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      label: '$label toggle',
      toggled: value,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: theme.colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.subtitle, required this.onRefresh});

  final String subtitle;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'LINEUP',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.78),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onRefresh,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.22)),
            ),
            child: const Icon(
              Icons.forum_outlined,
              size: 28,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuoteHighlight extends StatelessWidget {
  const _QuoteHighlight({
    required this.quote,
    required this.placeholder,
    required this.fallbackAuthor,
  });

  final Quote? quote;
  final String placeholder;
  final String fallbackAuthor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String text = quote?.text ?? placeholder;
    final String author =
        (quote?.author.isEmpty ?? true) ? fallbackAuthor : quote!.author;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            text,
            key: ValueKey<String>(text),
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          '— $author',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white.withOpacity(0.85),
            fontStyle: FontStyle.italic,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DismissibleQuoteTile extends StatelessWidget {
  const _DismissibleQuoteTile({
    required this.quote,
    required this.onDismissed,
    required this.isLast,
    required this.fallbackAuthor,
  });

  final Quote quote;
  final VoidCallback onDismissed;
  final bool isLast;
  final String fallbackAuthor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Dismissible(
        key: ValueKey<String>(quote.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismissed(),
        background: Container(
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                quote.text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                quote.author.isEmpty
                    ? '— $fallbackAuthor'
                    : '— ${quote.author}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.72),
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

