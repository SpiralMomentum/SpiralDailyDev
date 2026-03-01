import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utils/result/result.dart';

import '../../domain/entities/comment.dart';
import '../../domain/usecases/add_comment.dart';
import '../../domain/usecases/watch_comments.dart';
import 'comments_event.dart';
import 'comments_state.dart';

class _CommentsUpdated extends CommentsEvent {
  const _CommentsUpdated(this.comments);

  final List<Comment> comments;

  @override
  List<Object?> get props => [comments];
}

class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  CommentsBloc({
    required WatchComments watchComments,
    required AddComment addComment,
  })  : _watchComments = watchComments,
        _addComment = addComment,
        super(const CommentsState()) {
    on<CommentsStarted>(_onStarted);
    on<CommentAdded>(_onCommentAdded);
    on<CommentsRefreshed>(_onRefreshed);
    on<_CommentsUpdated>(_onCommentsUpdated);
  }

  final WatchComments _watchComments;
  final AddComment _addComment;
  StreamSubscription<List<Comment>>? _subscription;

  Future<void> _onStarted(
    CommentsStarted event,
    Emitter<CommentsState> emit,
  ) async {
    emit(state.copyWith(status: CommentsStatus.loading));
    await _subscription?.cancel();
    _subscription = _watchComments(event.articleId).listen(
      (comments) => add(_CommentsUpdated(comments)),
    );
  }

  void _onCommentsUpdated(
    _CommentsUpdated event,
    Emitter<CommentsState> emit,
  ) {
    final comments = event.comments;
    // Merge: keep optimistic comments that are not yet confirmed
    final confirmedIds = comments.map((c) => c.id).toSet();
    final optimistic = state.comments
        .where((c) => c.isOptimistic && !confirmedIds.contains(c.id))
        .toList();
    emit(state.copyWith(
      status: CommentsStatus.loaded,
      comments: [...comments, ...optimistic],
      errorMessage: () => null,
    ));
  }

  Future<void> _onCommentAdded(
    CommentAdded event,
    Emitter<CommentsState> emit,
  ) async {
    // Optimistic update
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticComment = Comment(
      id: tempId,
      articleId: event.articleId,
      parentId: event.parentId,
      authorName: event.authorName,
      content: event.content,
      createdAt: DateTime.now(),
      isOptimistic: true,
    );

    emit(state.copyWith(
      comments: [...state.comments, optimisticComment],
    ));

    final result = await _addComment(
      articleId: event.articleId,
      parentId: event.parentId,
      authorName: event.authorName,
      content: event.content,
    );

    switch (result) {
      case Success(data: final comment):
        // Replace optimistic comment with the real one
        final updated = state.comments.map((c) {
          if (c.id == tempId) return comment;
          return c;
        }).toList();
        emit(state.copyWith(comments: updated));
      case ErrorResult(failure: final failure):
        // Remove optimistic comment on failure
        final rolled = state.comments.where((c) => c.id != tempId).toList();
        emit(state.copyWith(
          comments: rolled,
          errorMessage: () => failure.message,
        ));
    }
  }

  Future<void> _onRefreshed(
    CommentsRefreshed event,
    Emitter<CommentsState> emit,
  ) async {
    // Stream-based: no manual refresh needed, but re-emit loading
    emit(state.copyWith(status: CommentsStatus.loading));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
