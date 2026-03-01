import 'package:flutter/material.dart';

import 'package:apps.news_reader/features/news_feed/domain/entities/article.dart';

class CategorySelector extends StatelessWidget {
  const CategorySelector({
    super.key,
    required this.selectedCategories,
    required this.onChanged,
    this.minimumRequired = 3,
  });

  final List<ArticleCategory> selectedCategories;
  final ValueChanged<List<ArticleCategory>> onChanged;
  final int minimumRequired;

  bool get isValid => selectedCategories.length >= minimumRequired;

  @override
  Widget build(BuildContext context) {
    final categories = ArticleCategory.values
        .where((c) => c != ArticleCategory.unknown)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select at least $minimumRequired categories',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isValid
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.error,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '${selectedCategories.length} selected',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((category) {
            final isSelected = selectedCategories.contains(category);
            return FilterChip(
              key: ValueKey('category_chip_${category.name}'),
              label: Text(category.name),
              selected: isSelected,
              onSelected: (selected) {
                final updated = List<ArticleCategory>.from(selectedCategories);
                if (selected) {
                  updated.add(category);
                } else {
                  updated.remove(category);
                }
                onChanged(updated);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
