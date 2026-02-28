import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/article_detail_bloc.dart';
import '../bloc/article_detail_event.dart';
import '../bloc/article_detail_state.dart';

class ArticleDetailPage extends StatelessWidget {
  const ArticleDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArticleDetailBloc, ArticleDetailState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            actions: [
              if (state.article != null) ...[
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: () {
                    context.push('/article/${state.article!.id}/comments');
                  },
                ),
                IconButton(
                  icon: Icon(
                    state.article!.isBookmarked
                        ? Icons.bookmark
                        : Icons.bookmark_outline,
                  ),
                  onPressed: () {
                    context
                        .read<ArticleDetailBloc>()
                        .add(const ArticleDetailBookmarkToggled());
                  },
                ),
              ],
            ],
          ),
          body: switch (state.status) {
            ArticleDetailStatus.initial ||
            ArticleDetailStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            ArticleDetailStatus.error => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(state.errorMessage ?? 'Failed to load article'),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () {
                          context
                              .read<ArticleDetailBloc>()
                              .add(const ArticleDetailRefreshed());
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ArticleDetailStatus.loaded => _ArticleContent(state: state),
          },
        );
      },
    );
  }
}

class _ArticleContent extends StatelessWidget {
  const _ArticleContent({required this.state});
  final ArticleDetailState state;

  @override
  Widget build(BuildContext context) {
    final article = state.article!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (article.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                article.imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.image, color: theme.colorScheme.outline),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Chip(label: Text(article.category.name)),
          const SizedBox(height: 8),
          Text(
            article.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            article.summary,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            article.content,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          if (article.commentCount > 0) ...[
            const SizedBox(height: 24),
            Text(
              '${article.commentCount} comments',
              style: theme.textTheme.titleSmall,
            ),
          ],
        ],
      ),
    );
  }
}
