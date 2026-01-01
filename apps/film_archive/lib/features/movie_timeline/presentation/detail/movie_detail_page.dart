import 'package:flutter/material.dart';

import 'package:utils/utils.dart';

import 'movie_detail_view_data.dart';
import 'movie_detail_view_model.dart';

class MovieDetailPage extends StatefulWidget {
  const MovieDetailPage({
    super.key,
    required this.viewModel,
    required this.title,
  });

  final MovieDetailViewModel viewModel;
  final String title;

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  late Future<Result<MovieDetailViewData>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.viewModel.load();
  }

  void _retry() {
    setState(() {
      _future = widget.viewModel.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder<Result<MovieDetailViewData>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = snapshot.data;
          if (result == null) {
            return _ErrorState(
              message: '해당 영화 정보를 찾을 수 없습니다.',
              onRetry: _retry,
            );
          }
          return result.when(
            success: (detail) => _MovieDetailBody(detail: detail),
            error: (failure) => _ErrorState(
              message: failure.message ??
                  '영화 정보를 불러올 수 없습니다.\n네트워크 상태를 확인 후 다시 시도해주세요.',
              onRetry: _retry,
            ),
          );
        },
      ),
    );
  }
}

class _MovieDetailBody extends StatelessWidget {
  const _MovieDetailBody({required this.detail});

  final MovieDetailViewData detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.title,
            style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ) ??
                const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _InfoRow(label: '개봉 연도', value: detail.yearText),
          _InfoRow(label: '제작 국가', value: detail.countriesText),
          _InfoRow(label: '장르', value: detail.genreText),
          _InfoRow(label: '러닝타임', value: detail.runtimeText),
          _InfoRow(label: '평점', value: detail.ratingText),
          const SizedBox(height: 24),
          Text(
            '소개',
            style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            detail.overview,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
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
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
