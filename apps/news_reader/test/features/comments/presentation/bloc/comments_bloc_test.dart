import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/result/result.dart';
import 'package:utils/result/failure.dart';

import 'package:apps.news_reader/features/comments/domain/entities/comment.dart';
import 'package:apps.news_reader/features/comments/domain/usecases/watch_comments.dart';
import 'package:apps.news_reader/features/comments/domain/usecases/add_comment.dart';
import 'package:apps.news_reader/features/comments/presentation/bloc/comments_bloc.dart';
import 'package:apps.news_reader/features/comments/presentation/bloc/comments_event.dart';
import 'package:apps.news_reader/features/comments/presentation/bloc/comments_state.dart';

class MockWatchComments extends Mock implements WatchComments {}

class MockAddComment extends Mock implements AddComment {}

void main() {
  late MockWatchComments watchComments;
  late MockAddComment addComment;

  final tComment = Comment(
    id: 'c1',
    articleId: 'a1',
    authorName: 'Author',
    content: 'Hello',
    createdAt: DateTime(2024, 1, 1),
  );

  final tComment2 = Comment(
    id: 'c2',
    articleId: 'a1',
    authorName: 'Author2',
    content: 'World',
    createdAt: DateTime(2024, 1, 2),
  );

  setUp(() {
    watchComments = MockWatchComments();
    addComment = MockAddComment();
  });

  CommentsBloc buildBloc() => CommentsBloc(
        watchComments: watchComments,
        addComment: addComment,
      );

  group('CommentsBloc', () {
    blocTest<CommentsBloc, CommentsState>(
      'emits [loading, loaded] when CommentsStarted and stream emits',
      build: () {
        when(() => watchComments('a1'))
            .thenAnswer((_) => Stream.value([tComment]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const CommentsStarted('a1')),
      wait: const Duration(milliseconds: 50),
      expect: () => [
        const CommentsState(status: CommentsStatus.loading),
        CommentsState(
          status: CommentsStatus.loaded,
          comments: [tComment],
        ),
      ],
    );

    blocTest<CommentsBloc, CommentsState>(
      'emits loaded with empty list when stream emits empty',
      build: () {
        when(() => watchComments('a2'))
            .thenAnswer((_) => Stream.value([]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const CommentsStarted('a2')),
      wait: const Duration(milliseconds: 50),
      expect: () => [
        const CommentsState(status: CommentsStatus.loading),
        const CommentsState(
          status: CommentsStatus.loaded,
          comments: [],
        ),
      ],
    );

    blocTest<CommentsBloc, CommentsState>(
      'performs optimistic add and replaces on success',
      build: () {
        final controller = StreamController<List<Comment>>();
        when(() => watchComments('a1'))
            .thenAnswer((_) => controller.stream);
        when(() => addComment(
              articleId: any(named: 'articleId'),
              parentId: any(named: 'parentId'),
              authorName: any(named: 'authorName'),
              content: any(named: 'content'),
            )).thenAnswer((_) async => Success(tComment2));
        return buildBloc();
      },
      seed: () => CommentsState(
        status: CommentsStatus.loaded,
        comments: [tComment],
      ),
      act: (bloc) => bloc.add(CommentAdded(
        articleId: 'a1',
        authorName: 'Author2',
        content: 'World',
      )),
      wait: const Duration(milliseconds: 50),
      expect: () => [
        // First: optimistic add (comment with isOptimistic=true appended)
        isA<CommentsState>()
            .having((s) => s.comments.length, 'count', 2)
            .having((s) => s.comments.last.isOptimistic, 'optimistic', true)
            .having((s) => s.comments.last.content, 'content', 'World'),
        // Second: replaced with real comment
        isA<CommentsState>()
            .having((s) => s.comments.length, 'count', 2)
            .having(
                (s) => s.comments.last.isOptimistic, 'not optimistic', false)
            .having((s) => s.comments.last.id, 'real id', 'c2'),
      ],
    );

    blocTest<CommentsBloc, CommentsState>(
      'rolls back optimistic comment on failure',
      build: () {
        final controller = StreamController<List<Comment>>();
        when(() => watchComments('a1'))
            .thenAnswer((_) => controller.stream);
        when(() => addComment(
              articleId: any(named: 'articleId'),
              parentId: any(named: 'parentId'),
              authorName: any(named: 'authorName'),
              content: any(named: 'content'),
            )).thenAnswer((_) async => ErrorResult(
              const NetworkFailure(message: 'Failed to add comment'),
            ));
        return buildBloc();
      },
      seed: () => CommentsState(
        status: CommentsStatus.loaded,
        comments: [tComment],
      ),
      act: (bloc) => bloc.add(CommentAdded(
        articleId: 'a1',
        authorName: 'Author2',
        content: 'Failed comment',
      )),
      wait: const Duration(milliseconds: 50),
      expect: () => [
        // First: optimistic add
        isA<CommentsState>()
            .having((s) => s.comments.length, 'count', 2)
            .having((s) => s.comments.last.isOptimistic, 'optimistic', true),
        // Second: rollback - removed optimistic, error message set
        isA<CommentsState>()
            .having((s) => s.comments.length, 'count', 1)
            .having((s) => s.comments.first.id, 'original remains', 'c1')
            .having(
                (s) => s.errorMessage, 'error', 'Failed to add comment'),
      ],
    );

    blocTest<CommentsBloc, CommentsState>(
      'emits loading on CommentsRefreshed',
      build: buildBloc,
      seed: () => CommentsState(
        status: CommentsStatus.loaded,
        comments: [tComment],
      ),
      act: (bloc) => bloc.add(const CommentsRefreshed()),
      expect: () => [
        CommentsState(
          status: CommentsStatus.loading,
          comments: [tComment],
        ),
      ],
    );

    blocTest<CommentsBloc, CommentsState>(
      'passes parentId when adding reply comment',
      build: () {
        final controller = StreamController<List<Comment>>();
        when(() => watchComments('a1'))
            .thenAnswer((_) => controller.stream);
        when(() => addComment(
              articleId: any(named: 'articleId'),
              parentId: any(named: 'parentId'),
              authorName: any(named: 'authorName'),
              content: any(named: 'content'),
            )).thenAnswer((_) async => Success(
              tComment2.copyWith(parentId: () => 'c1'),
            ));
        return buildBloc();
      },
      seed: () => CommentsState(
        status: CommentsStatus.loaded,
        comments: [tComment],
      ),
      act: (bloc) => bloc.add(CommentAdded(
        articleId: 'a1',
        parentId: 'c1',
        authorName: 'Author2',
        content: 'Reply',
      )),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => addComment(
              articleId: 'a1',
              parentId: 'c1',
              authorName: 'Author2',
              content: 'Reply',
            )).called(1);
      },
    );

    test('cancels subscription on close', () async {
      final controller = StreamController<List<Comment>>();
      when(() => watchComments('a1'))
          .thenAnswer((_) => controller.stream);

      final bloc = buildBloc();
      bloc.add(const CommentsStarted('a1'));
      await Future.delayed(const Duration(milliseconds: 50));

      await bloc.close();

      // StreamController should still be closeable (not already listened to after cancel)
      expect(controller.hasListener, isFalse);
      await controller.close();
    });
  });
}
