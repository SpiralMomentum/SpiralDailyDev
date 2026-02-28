import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:apps.news_reader/features/news_feed/domain/entities/article.dart';
import '../bloc/news_feed_bloc.dart';
import '../bloc/news_feed_event.dart';
import '../bloc/news_feed_state.dart';

class NewsFeedPage extends StatelessWidget {
  const NewsFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News Reader'),
      ),
      body: Column(
        children: [
          _CategoryFilter(),
          Expanded(child: _ArticleList()),
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewsFeedBloc, NewsFeedState>(
      buildWhen: (prev, curr) => prev.selectedCategory != curr.selectedCategory,
      builder: (context, state) {
        return SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildChip(context, null, state.selectedCategory),
              ...ArticleCategory.values.map(
                (c) => _buildChip(context, c, state.selectedCategory),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(
    BuildContext context,
    ArticleCategory? category,
    ArticleCategory? selected,
  ) {
    final isSelected = category == selected;
    final label = category?.name ?? 'All';

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          context.read<NewsFeedBloc>().add(NewsFeedCategoryChanged(category));
        },
      ),
    );
  }
}

class _ArticleList extends StatefulWidget {
  @override
  State<_ArticleList> createState() => _ArticleListState();
}

class _ArticleListState extends State<_ArticleList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    if (currentScroll >= maxScroll * 0.8) {
      context.read<NewsFeedBloc>().add(const NewsFeedNextPageRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewsFeedBloc, NewsFeedState>(
      builder: (context, state) {
        switch (state.status) {
          case NewsFeedStatus.initial:
          case NewsFeedStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case NewsFeedStatus.error:
            return _ErrorView(message: state.errorMessage ?? 'Unknown error');
          case NewsFeedStatus.loaded:
            if (state.articles.isEmpty) {
              return const Center(child: Text('No articles found'));
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<NewsFeedBloc>().add(const NewsFeedRefreshed());
              },
              child: ListView.builder(
                controller: _scrollController,
                itemCount: state.articles.length + (state.isLoadingMore ? 1 : 0),
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  if (index == state.articles.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  final article = state.articles[index];
                  return _ArticleCard(article: article);
                },
              ),
            );
        }
      },
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article});
  final Article article;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/article/${article.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  article.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.image, color: theme.colorScheme.outline),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          article.category.name,
                          style: theme.textTheme.labelSmall,
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          article.isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_outline,
                        ),
                        onPressed: () {
                          context.read<NewsFeedBloc>().add(
                                NewsFeedBookmarkToggled(article),
                              );
                        },
                        iconSize: 20,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.summary,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                context.read<NewsFeedBloc>().add(const NewsFeedRefreshed());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
