import 'package:flutter/material.dart';
import 'package:utils/result/failure.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.failure,
    this.onRetry,
    this.compact = false,
  });

  final Failure failure;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (compact) {
      return _CompactErrorView(
        icon: _iconForFailure(failure),
        message: _messageForFailure(failure),
        onRetry: onRetry,
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconForFailure(failure),
              size: 64,
              color: theme.colorScheme.error.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              _titleForFailure(failure),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _messageForFailure(failure),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('재시도'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static IconData _iconForFailure(Failure failure) {
    if (failure is NetworkFailure) return Icons.wifi_off;
    if (failure is LocalStorageFailure) return Icons.storage;
    return Icons.error_outline;
  }

  static String _titleForFailure(Failure failure) {
    if (failure is NetworkFailure) return '네트워크 오류';
    if (failure is LocalStorageFailure) return '저장소 오류';
    return '오류 발생';
  }

  static String _messageForFailure(Failure failure) {
    if (failure is NetworkFailure) {
      final msg = (failure.message ?? '').toLowerCase();
      if (msg.contains('timeout') || msg.contains('5')) {
        return '서버 오류입니다. 잠시 후 다시 시도해 주세요.';
      }
      return '네트워크 오류입니다. 연결 상태를 확인해 주세요.';
    }
    if (failure is LocalStorageFailure) {
      return '로컬 저장소 오류가 발생했습니다.';
    }
    return '예상치 못한 오류가 발생했습니다.';
  }
}

class _CompactErrorView extends StatelessWidget {
  const _CompactErrorView({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          if (onRetry != null)
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: onRetry,
              tooltip: '재시도',
            ),
        ],
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
