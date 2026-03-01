import 'package:utils/result/result.dart';
import 'package:utils/result/failure.dart';

import '../../domain/entities/comment.dart';
import '../../domain/repositories/comment_repository.dart';
import '../datasources/comment_data_source.dart';
import '../mappers/comment_mapper.dart';

class CommentRepositoryImpl implements CommentRepository {
  const CommentRepositoryImpl({
    required CommentDataSource dataSource,
  }) : _dataSource = dataSource;

  final CommentDataSource _dataSource;

  @override
  Stream<List<Comment>> watchComments(String articleId) {
    return _dataSource.watchComments(articleId).map(
          (dtos) => dtos.map(CommentMapper.toDomain).toList(),
        );
  }

  @override
  Future<Result<Comment>> addComment({
    required String articleId,
    String? parentId,
    required String authorName,
    required String content,
  }) async {
    try {
      final dto = await _dataSource.addComment(
        articleId: articleId,
        parentId: parentId,
        authorName: authorName,
        content: content,
      );
      return Success(CommentMapper.toDomain(dto));
    } catch (e, st) {
      return ErrorResult(
        NetworkFailure(
          message: e.toString(),
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
