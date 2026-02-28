import 'package:equatable/equatable.dart';

import '../../domain/entities/comment.dart';

enum CommentsStatus { initial, loading, loaded, error }

class CommentsState extends Equatable {
  const CommentsState({
    this.status = CommentsStatus.initial,
    this.comments = const [],
    this.errorMessage,
  });

  final CommentsStatus status;
  final List<Comment> comments;
  final String? errorMessage;

  CommentsState copyWith({
    CommentsStatus? status,
    List<Comment>? comments,
    String? Function()? errorMessage,
  }) {
    return CommentsState(
      status: status ?? this.status,
      comments: comments ?? this.comments,
      errorMessage:
          errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, comments, errorMessage];
}
