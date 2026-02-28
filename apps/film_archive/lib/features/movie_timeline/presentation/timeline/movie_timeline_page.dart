import 'package:app_analytics/app_analytics.dart';
import 'package:flutter/material.dart';

import 'package:film_archive/features/movie_timeline/domain/entities/movie_sort_option.dart';
import 'package:film_archive/features/movie_timeline/domain/entities/movie_summary.dart';
import 'package:film_archive/features/movie_timeline/domain/usecases/get_movie_detail_use_case.dart';
import 'package:film_archive/features/movie_timeline/domain/usecases/get_movie_timeline_use_case.dart';

import '../detail/movie_detail_page.dart';
import '../detail/movie_detail_view_model.dart';
import 'movie_timeline_controller.dart';
import 'movie_timeline_state.dart';

class MovieTimelinePage extends StatefulWidget {
  const MovieTimelinePage({
    super.key,
    required this.getMovieTimelineUseCase,
    required this.getMovieDetailUseCase,
    this.analyticsTracker,
  });

  final GetMovieTimelineUseCase getMovieTimelineUseCase;
  final GetMovieDetailUseCase getMovieDetailUseCase;
  final AnalyticsTracker? analyticsTracker;

  @override
  State<MovieTimelinePage> createState() => _MovieTimelinePageState();
}

class _MovieTimelinePageState extends State<MovieTimelinePage> {
  late final TextEditingController _startYearController;
  late final TextEditingController _endYearController;
  late final FocusNode _startYearFocusNode;
  late final MovieTimelineController _controller;

  @override
  void initState() {
    super.initState();
    final currentYear = DateTime.now().year;
    _startYearController = TextEditingController();
    _endYearController = TextEditingController(text: '$currentYear');
    _startYearFocusNode = FocusNode();
    _controller = MovieTimelineController(
      getMovieTimelineUseCase: widget.getMovieTimelineUseCase,
      analyticsTracker: widget.analyticsTracker,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startYearFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _startYearController.dispose();
    _endYearController.dispose();
    _startYearFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _buildTimeline() {
    _controller.buildTimeline(
      startYearText: _startYearController.text.trim(),
      endYearText: _endYearController.text.trim(),
    );
  }

  void _openDetail(MovieSummary summary) {
    _controller.trackMovieDetailViewed(
      movieId: summary.id,
      title: summary.title,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MovieDetailPage(
          viewModel: MovieDetailViewModel(
            getMovieDetailUseCase: widget.getMovieDetailUseCase,
            movieId: summary.id,
          ),
          title: summary.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(
            title: const Text('연도별 최고 흥행작 타임라인'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '연도 범위를 선택하세요',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _YearInputField(
                                label: '시작 연도',
                                controller: _startYearController,
                                focusNode: _startYearFocusNode,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('~'),
                            ),
                            Expanded(
                              child: _YearInputField(
                                label: '종료 연도',
                                controller: _endYearController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonHideUnderline(
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: '검색 기준',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            child: DropdownButton<MovieSortOption>(
                              isExpanded: true,
                              value: state.sortOption,
                              items: MovieSortOption.values
                                  .map(
                                    (option) => DropdownMenuItem(
                                      value: option,
                                      child: Text(option.displayLabel),
                                    ),
                                  )
                                  .toList(),
                              onChanged: state.isLoading
                                  ? null
                                  : (option) {
                                      if (option != null) {
                                        _controller.selectSortOption(option);
                                      }
                                    },
                            ),
                          ),
                        ),
                        if (state.inputMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            state.inputMessage!,
                            style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.error,
                                ) ??
                                TextStyle(
                                  color: theme.colorScheme.error,
                                  fontSize: 12,
                                ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: state.isLoading ? null : _buildTimeline,
                            icon: const Icon(Icons.timeline, semanticLabel: '타임라인'),
                            label: const Text('타임라인 만들기'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.noticeMessage != null &&
                    state.timeline.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.noticeMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ) ??
                        TextStyle(color: theme.colorScheme.secondary),
                  ),
                ],
                const SizedBox(height: 16),
                Expanded(
                  child: _TimelineBody(
                    state: state,
                    onTap: _openDetail,
                    onRetry: _buildTimeline,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TimelineBody extends StatelessWidget {
  const _TimelineBody({
    required this.state,
    required this.onTap,
    required this.onRetry,
  });

  final MovieTimelineState state;
  final void Function(MovieSummary summary) onTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null) {
      return _ErrorState(
        message: state.errorMessage!,
        onRetry: onRetry,
      );
    }
    if (state.timeline.isEmpty) {
      return const _EmptyTimelineState();
    }
    return ListView.separated(
      itemCount: state.timeline.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final movie = state.timeline[index];
        return Semantics(
          label: '${movie.year}년 영화: ${movie.title}',
          child: TimelineMovieCard(
            summary: movie,
            onTap: () => onTap(movie),
          ),
        );
      },
    );
  }
}

class _YearInputField extends StatelessWidget {
  const _YearInputField({
    required this.label,
    required this.controller,
    this.focusNode,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      style: theme.textTheme.bodyMedium,
    );
  }
}

class TimelineMovieCard extends StatelessWidget {
  const TimelineMovieCard({
    super.key,
    required this.summary,
    required this.onTap,
  });

  final MovieSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 56,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${summary.year}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 24,
                      height: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.displayOverview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: theme.colorScheme.primary,
                          semanticLabel: '영화 상세 보기',
                        ),
                        Text(
                          '영화 상세 보기',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTimelineState extends StatelessWidget {
  const _EmptyTimelineState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.movie_creation_outlined,
            size: 48,
            color: theme.colorScheme.primary,
            semanticLabel: '영화 타임라인 안내',
          ),
          const SizedBox(height: 12),
          Text(
            '연도를 선택해 타임라인을 만들어보세요.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, semanticLabel: '다시 시도'),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
