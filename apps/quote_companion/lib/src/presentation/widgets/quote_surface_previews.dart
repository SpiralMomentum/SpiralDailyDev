import 'package:flutter/material.dart';

import '../../domain/entities/quote.dart';
import '../../domain/entities/quote_display_preferences.dart';
import '../l10n/app_localizations.dart';

/// Visual previews for configured quote surfaces such as the status bar
/// and home widget. The previews help validate toggles without requiring
/// a full device integration.
class QuoteSurfacePreviews extends StatelessWidget {
  /// Creates a [QuoteSurfacePreviews] widget.
  const QuoteSurfacePreviews({
    super.key,
    required this.quote,
    required this.preferences,
  });

  /// Quote currently highlighted by the experience.
  final Quote quote;

  /// User's configured display preferences.
  final QuoteDisplayPreferences preferences;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    final List<Widget> children = <Widget>[
      Text(
        l10n.translate('previewHeader'),
        style: theme.textTheme.titleMedium,
      ),
      const SizedBox(height: 12),
      if (preferences.isTargetEnabled(QuoteDisplayTarget.statusBar))
        _StatusBarPreview(quote: quote, l10n: l10n)
      else
        _SurfaceDisabledNotice(title: l10n.translate('statusBarLabel')),
      const SizedBox(height: 12),
      if (preferences.isTargetEnabled(QuoteDisplayTarget.homeWidget))
        _HomeWidgetPreview(quote: quote, l10n: l10n)
      else
        _SurfaceDisabledNotice(title: l10n.translate('homeWidgetLabel')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _StatusBarPreview extends StatelessWidget {
  const _StatusBarPreview({required this.quote, required this.l10n});

  final Quote quote;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color foreground = theme.colorScheme.onPrimary;
    final String author =
        quote.author.isEmpty ? l10n.translate('appTitle') : quote.author;

    return Semantics(
      label: 'status-bar-preview',
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: <Widget>[
              Icon(Icons.format_quote_rounded, size: 16, color: foreground),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  quote.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(color: foreground),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                author,
                style:
                    theme.textTheme.labelSmall?.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeWidgetPreview extends StatelessWidget {
  const _HomeWidgetPreview({required this.quote, required this.l10n});

  final Quote quote;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String author =
        quote.author.isEmpty ? l10n.translate('appTitle') : quote.author;

    return Semantics(
      label: 'home-widget-preview',
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surfaceVariant,
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                l10n.translate('homeWidgetLabel'),
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '“${quote.text}”',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '— $author',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurfaceDisabledNotice extends StatelessWidget {
  const _SurfaceDisabledNotice({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Semantics(
      label: 'surface-disabled',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Icon(Icons.visibility_off_outlined,
                color: theme.colorScheme.outline),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$title · ${l10n.translate('surfaceDisabledHint')}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
