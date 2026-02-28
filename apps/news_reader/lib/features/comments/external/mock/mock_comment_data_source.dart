import 'dart:async';

import '../../data/datasources/comment_data_source.dart';
import '../../data/dto/comment_dto.dart';

class MockCommentDataSource implements CommentDataSource {
  MockCommentDataSource() {
    _initSampleData();
  }

  final Map<String, List<CommentDto>> _store = {};
  final _controller = StreamController<void>.broadcast();
  int _idCounter = 100;

  void _initSampleData() {
    _store['article-1'] = [
      const CommentDto(
        id: 'c1',
        article_id: 'article-1',
        author_name: '김민수',
        content: '좋은 기사 감사합니다.',
        created_at: '2024-06-01T09:00:00Z',
      ),
      const CommentDto(
        id: 'c2',
        article_id: 'article-1',
        parent_id: 'c1',
        author_name: '이영희',
        content: '저도 동감합니다!',
        created_at: '2024-06-01T09:30:00Z',
      ),
      const CommentDto(
        id: 'c3',
        article_id: 'article-1',
        author_name: '박지훈',
        content: '더 자세한 분석이 필요할 것 같습니다.',
        created_at: '2024-06-01T10:00:00Z',
      ),
    ];
  }

  @override
  Stream<List<CommentDto>> watchComments(String articleId) async* {
    // Emit current data immediately
    yield _store[articleId] ?? [];

    // Emit on every change
    await for (final _ in _controller.stream) {
      yield _store[articleId] ?? [];
    }
  }

  @override
  Future<CommentDto> addComment({
    required String articleId,
    String? parentId,
    required String authorName,
    required String content,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final dto = CommentDto(
      id: 'c${++_idCounter}',
      article_id: articleId,
      parent_id: parentId,
      author_name: authorName,
      content: content,
      created_at: DateTime.now().toIso8601String(),
    );

    _store.putIfAbsent(articleId, () => []);
    _store[articleId]!.add(dto);
    _controller.add(null);

    return dto;
  }

  void dispose() {
    _controller.close();
  }
}
