import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:apps.news_reader/core/haptic/haptic_service.dart';
import '../../domain/entities/comment.dart';
import '../bloc/comments_bloc.dart';
import '../bloc/comments_event.dart';
import '../bloc/comments_state.dart';

class CommentsPage extends StatefulWidget {
  const CommentsPage({
    super.key,
    required this.articleId,
  });

  final String articleId;

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final _controller = TextEditingController();
  final _authorController = TextEditingController(text: '익명');

  @override
  void dispose() {
    _controller.dispose();
    _authorController.dispose();
    super.dispose();
  }

  void _submit() {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    HapticService.commentPosted();
    context.read<CommentsBloc>().add(CommentAdded(
          articleId: widget.articleId,
          authorName: _authorController.text.trim().isEmpty
              ? '익명'
              : _authorController.text.trim(),
          content: content,
        ));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('댓글')),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<CommentsBloc, CommentsState>(
              builder: (context, state) {
                if (state.status == CommentsStatus.loading &&
                    state.comments.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == CommentsStatus.error &&
                    state.comments.isEmpty) {
                  return Center(
                    child: Text(state.errorMessage ?? '오류가 발생했습니다'),
                  );
                }

                if (state.comments.isEmpty) {
                  return const Center(
                    child: Text('첫 댓글을 남겨보세요'),
                  );
                }

                return _CommentThreadList(comments: state.comments);
              },
            ),
          ),
          const Divider(height: 1),
          _CommentInput(
            controller: _controller,
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }
}

class _CommentThreadList extends StatelessWidget {
  const _CommentThreadList({required this.comments});

  final List<Comment> comments;

  @override
  Widget build(BuildContext context) {
    final rootComments =
        comments.where((c) => c.parentId == null).toList();
    final replyMap = <String, List<Comment>>{};
    for (final comment in comments) {
      if (comment.parentId != null) {
        replyMap.putIfAbsent(comment.parentId!, () => []).add(comment);
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: rootComments.length,
      itemBuilder: (context, index) {
        final root = rootComments[index];
        final replies = replyMap[root.id] ?? [];
        return _CommentThread(root: root, replies: replies);
      },
    );
  }
}

class _CommentThread extends StatelessWidget {
  const _CommentThread({required this.root, required this.replies});

  final Comment root;
  final List<Comment> replies;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CommentTile(comment: root),
        ...replies.map(
          (reply) => Padding(
            padding: const EdgeInsets.only(left: 32),
            child: _CommentTile(comment: reply),
          ),
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final Comment comment;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${comment.authorName}의 댓글',
      child: Opacity(
        opacity: comment.isOptimistic ? 0.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.authorName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(comment.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(comment.content),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}

class _CommentInput extends StatelessWidget {
  const _CommentInput({
    required this.controller,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: '댓글을 입력하세요',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onSubmitted: (_) => onSubmit(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send),
              tooltip: '댓글 작성',
              onPressed: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
