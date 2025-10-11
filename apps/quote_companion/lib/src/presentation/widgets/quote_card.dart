import 'package:flutter/material.dart';

import '../../domain/entities/quote.dart';

/// Card widget displaying a quote with accessible semantics.
class QuoteCard extends StatelessWidget {
  /// Creates a [QuoteCard].
  const QuoteCard({super.key, required this.quote});

  /// Quote to render.
  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      label: 'quote-card',
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '“${quote.text}”',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                quote.author.isEmpty ? '—' : '— ${quote.author}',
                style: theme.textTheme.titleMedium?.copyWith(
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
