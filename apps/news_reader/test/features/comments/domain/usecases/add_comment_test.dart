import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/result/result.dart';
import 'package:utils/result/failure.dart';

import 'package:apps.news_reader/features/comments/domain/entities/comment.dart';
import 'package:apps.news_reader/features/comments/domain/repositories/comment_repository.dart';
import 'package:apps.news_reader/features/comments/domain/usecases/add_comment.dart';

class MockCommentRepository extends Mock implements CommentRepository {}

void main() {
  late MockCommentRepository repository;
  late AddComment usecase;

  final tComment = Comment(
    id: '1',
    articleId: 'a1',
    authorName: 'Author',
    content: 'Hello',
    createdAt: DateTime(2024, 1, 1),
  );

  setUp(() {
    repository = MockCommentRepository();
    usecase = AddComment(repository);
  });

  group('AddComment', () {
    test('returns Success when repository succeeds', () async {
      when(() => repository.addComment(
            articleId: any(named: 'articleId'),
            parentId: any(named: 'parentId'),
            authorName: any(named: 'authorName'),
            content: any(named: 'content'),
          )).thenAnswer((_) async => Success(tComment));

      final result = await usecase(
        articleId: 'a1',
        authorName: 'Author',
        content: 'Hello',
      );

      expect(result, isA<Success<Comment>>());
      expect((result as Success<Comment>).data, tComment);
      verify(() => repository.addComment(
            articleId: 'a1',
            parentId: null,
            authorName: 'Author',
            content: 'Hello',
          )).called(1);
    });

    test('returns ErrorResult when repository fails', () async {
      when(() => repository.addComment(
            articleId: any(named: 'articleId'),
            parentId: any(named: 'parentId'),
            authorName: any(named: 'authorName'),
            content: any(named: 'content'),
          )).thenAnswer(
        (_) async => ErrorResult(
            const NetworkFailure(message: 'Network error')),
      );

      final result = await usecase(
        articleId: 'a1',
        authorName: 'Author',
        content: 'Hello',
      );

      expect(result, isA<ErrorResult<Comment>>());
    });

    test('passes parentId when provided', () async {
      when(() => repository.addComment(
            articleId: any(named: 'articleId'),
            parentId: any(named: 'parentId'),
            authorName: any(named: 'authorName'),
            content: any(named: 'content'),
          )).thenAnswer(
              (_) async => Success(tComment.copyWith(parentId: () => 'p1')));

      await usecase(
        articleId: 'a1',
        parentId: 'p1',
        authorName: 'Author',
        content: 'Reply',
      );

      verify(() => repository.addComment(
            articleId: 'a1',
            parentId: 'p1',
            authorName: 'Author',
            content: 'Reply',
          )).called(1);
    });
  });
}
