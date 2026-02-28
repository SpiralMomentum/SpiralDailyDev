import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:apps.news_reader/features/news_feed/domain/entities/article.dart';
import '../cubit/search_cubit.dart';
import '../cubit/search_state.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SearchCubit>().loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search articles...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: BlocBuilder<SearchCubit, SearchState>(
                  buildWhen: (prev, curr) => prev.query != curr.query,
                  builder: (context, state) {
                    if (state.query.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        context.read<SearchCubit>().search('');
                      },
                    );
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                context.read<SearchCubit>().search(value);
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  context.read<SearchCubit>().saveQuery(value);
                }
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<SearchCubit, SearchState>(
              builder: (context, state) {
                if (state.query.isEmpty) {
                  return _SearchHistoryView(
                    history: state.searchHistory,
                    onTap: (query) {
                      _controller.text = query;
                      _controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: query.length),
                      );
                      context.read<SearchCubit>().search(query);
                      context.read<SearchCubit>().saveQuery(query);
                    },
                    onClear: () {
                      context.read<SearchCubit>().clearHistory();
                    },
                  );
                }

                switch (state.status) {
                  case SearchStatus.initial:
                    return const SizedBox.shrink();
                  case SearchStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case SearchStatus.error:
                    return Center(
                      child: Text(
                        state.errorMessage ?? 'An error occurred',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    );
                  case SearchStatus.loaded:
                    if (state.articles.isEmpty) {
                      return const Center(
                        child: Text('검색 결과가 없습니다'),
                      );
                    }
                    return _SearchResultList(
                      articles: state.articles,
                      hasMore: state.hasMore,
                      onLoadMore: () {
                        context.read<SearchCubit>().loadMore();
                      },
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchHistoryView extends StatelessWidget {
  const _SearchHistoryView({
    required this.history,
    required this.onTap,
    required this.onClear,
  });

  final List<String> history;
  final void Function(String query) onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: Text('No search history'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              TextButton(
                onPressed: onClear,
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: history.map((query) {
              return ActionChip(
                label: Text(query),
                onPressed: () => onTap(query),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SearchResultList extends StatefulWidget {
  const _SearchResultList({
    required this.articles,
    required this.hasMore,
    required this.onLoadMore,
  });

  final List<Article> articles;
  final bool hasMore;
  final VoidCallback onLoadMore;

  @override
  State<_SearchResultList> createState() => _SearchResultListState();
}

class _SearchResultListState extends State<_SearchResultList> {
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
    if (currentScroll >= maxScroll * 0.8 && widget.hasMore) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const PageStorageKey('search_results'),
      controller: _scrollController,
      itemCount: widget.articles.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final article = widget.articles[index];
        return _SearchResultCard(article: article);
      },
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.article});
  final Article article;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/article/${article.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
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
                  Text(
                    article.sourceName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
