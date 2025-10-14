import 'package:flutter/material.dart';

import '../../domain/entities/quote.dart';
import '../l10n/app_localizations.dart';

/// Displays how a quote appears across the live delivery surfaces.
class QuoteSurfaceShowcase extends StatelessWidget {
  /// Creates a [QuoteSurfaceShowcase].
  const QuoteSurfaceShowcase({
    super.key,
    required this.quote,
  });

  /// Quote currently broadcast across surfaces.
  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String author =
        quote.author.isEmpty ? l10n.translate('appTitle') : quote.author;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SurfaceSection(
          title: l10n.translate('statusBarLabel'),
          semanticLabel: 'status-bar-surface',
          child: _StatusBarSurface(
            quote: quote,
            author: author,
          ),
        ),
        const SizedBox(height: 16),
        _SurfaceSection(
          title: l10n.translate('lockScreenLabel'),
          semanticLabel: 'lock-screen-surface',
          child: _LockScreenSurface(
            quote: quote,
            author: author,
          ),
        ),
        const SizedBox(height: 16),
        _SurfaceSection(
          title: l10n.translate('homeWidgetLabel'),
          semanticLabel: 'home-widget-surface',
          child: _HomeWidgetSurface(
            quote: quote,
            author: author,
            l10n: l10n,
          ),
        ),
      ],
    );
  }
}

class _SurfaceSection extends StatelessWidget {
  const _SurfaceSection({
    required this.title,
    required this.semanticLabel,
    required this.child,
  });

  final String title;
  final String semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      label: semanticLabel,
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _StatusBarSurface extends StatelessWidget {
  const _StatusBarSurface({
    required this.quote,
    required this.author,
  });

  final Quote quote;
  final String author;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color foreground = theme.colorScheme.onPrimary;

    return DecoratedBox(
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
    );
  }
}

class _LockScreenSurface extends StatelessWidget {
  const _LockScreenSurface({
    required this.quote,
    required this.author,
  });

  final Quote quote;
  final String author;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: <Color>[
            theme.colorScheme.primary.withOpacity(0.92),
            theme.colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            quote.text,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '— $author',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary.withOpacity(0.85),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeWidgetSurface extends StatelessWidget {
  const _HomeWidgetSurface({
    required this.quote,
    required this.author,
    required this.l10n,
  });

  final Quote quote;
  final String author;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
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
    );
  }
}
