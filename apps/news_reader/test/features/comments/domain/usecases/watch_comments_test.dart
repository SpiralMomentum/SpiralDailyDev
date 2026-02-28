import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:apps.news_reader/features/comments/domain/entities/comment.dart';
import 'package:apps.news_reader/features/comments/domain/repositories/comment_repository.dart';
import 'package:apps.news_reader/features/comments/domain/usecases/watch_comments.dart';

class MockCommentRepository extends Mock implements CommentRepository {}

void main() {
  late MockCommentRepository repository;
  late WatchComments usecase;

  final tComments = [
    Comment(
      id: '1',
      articleId: 'a1',
      authorName: 'Author',
      content: 'Content',
      createdAt: DateTime(2024, 1, 1),
    ),
  ];

  setUp(() {
    repository = MockCommentRepository();
    usecase = WatchComments(repository);
  });

  group('WatchComments', () {
    test('delegates to repository.watchComments', () {
      when(() => repository.watchComments('a1'))
          .thenAnswer((_) => Stream.value(tComments));

      final stream = usecase('a1');

      expect(stream, emits(tComments));
      verify(() => repository.watchComments('a1')).called(1);
    });

    test('emits empty list when no comments', () {
      when(() => repository.watchComments('a2'))
          .thenAnswer((_) => Stream.value([]));

      final stream = usecase('a2');

      expect(stream, emits(<Comment>[]));
    });
  });
}
