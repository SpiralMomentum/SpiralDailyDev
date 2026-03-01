import 'package:flutter_test/flutter_test.dart';

import 'package:apps.news_reader/features/comments/data/dto/comment_dto.dart';
import 'package:apps.news_reader/features/comments/data/mappers/comment_mapper.dart';
import 'package:apps.news_reader/features/comments/domain/entities/comment.dart';

void main() {
  group('CommentMapper', () {
    group('toDomain', () {
      test('maps all fields correctly', () {
        final dto = CommentDto(
          id: 'c1',
          article_id: 'a1',
          parent_id: 'p1',
          author_name: 'Author',
          content: 'Hello',
          created_at: '2024-01-15T10:30:00Z',
        );

        final comment = CommentMapper.toDomain(dto);

        expect(comment.id, 'c1');
        expect(comment.articleId, 'a1');
        expect(comment.parentId, 'p1');
        expect(comment.authorName, 'Author');
        expect(comment.content, 'Hello');
        expect(comment.createdAt, DateTime.utc(2024, 1, 15, 10, 30));
        expect(comment.isOptimistic, false);
      });

      test('handles null parentId', () {
        final dto = CommentDto(
          id: 'c1',
          article_id: 'a1',
          author_name: 'Author',
          content: 'Root comment',
          created_at: '2024-01-01T00:00:00Z',
        );

        final comment = CommentMapper.toDomain(dto);

        expect(comment.parentId, isNull);
      });

      test('handles null created_at with fallback to now', () {
        final before = DateTime.now();
        final dto = CommentDto(
          id: 'c1',
          article_id: 'a1',
          author_name: 'Author',
          content: 'No date',
        );

        final comment = CommentMapper.toDomain(dto);
        final after = DateTime.now();

        expect(
          comment.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(
          comment.createdAt.isBefore(after.add(const Duration(seconds: 1))),
          isTrue,
        );
      });

      test('handles invalid created_at string with fallback', () {
        final before = DateTime.now();
        final dto = CommentDto(
          id: 'c1',
          article_id: 'a1',
          author_name: 'Author',
          content: 'Bad date',
          created_at: 'not-a-date',
        );

        final comment = CommentMapper.toDomain(dto);
        final after = DateTime.now();

        expect(
          comment.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(
          comment.createdAt.isBefore(after.add(const Duration(seconds: 1))),
          isTrue,
        );
      });
    });

    group('toDto', () {
      test('maps domain entity to dto', () {
        final comment = Comment(
          id: 'c1',
          articleId: 'a1',
          parentId: 'p1',
          authorName: 'Author',
          content: 'Hello',
          createdAt: DateTime.utc(2024, 1, 15, 10, 30),
        );

        final dto = CommentMapper.toDto(comment);

        expect(dto.id, 'c1');
        expect(dto.article_id, 'a1');
        expect(dto.parent_id, 'p1');
        expect(dto.author_name, 'Author');
        expect(dto.content, 'Hello');
        expect(dto.created_at, '2024-01-15T10:30:00.000Z');
      });

      test('maps null parentId correctly', () {
        final comment = Comment(
          id: 'c1',
          articleId: 'a1',
          authorName: 'Author',
          content: 'Root',
          createdAt: DateTime(2024),
        );

        final dto = CommentMapper.toDto(comment);

        expect(dto.parent_id, isNull);
      });
    });
  });
}
