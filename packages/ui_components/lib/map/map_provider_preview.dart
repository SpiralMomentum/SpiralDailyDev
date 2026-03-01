import 'package:flutter/material.dart';

/// Lightweight card that describes a map provider.
class MapProviderPreview extends StatelessWidget {
  const MapProviderPreview({
    super.key,
    required this.title,
    required this.description,
    required this.accentColor,
    this.onTap,
  });

  final String title;
  final String description;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [accentColor.withOpacity(0.9), accentColor.withOpacity(0.5)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white.withOpacity(0.95)),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Semantics(
      button: true,
      label: title,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
