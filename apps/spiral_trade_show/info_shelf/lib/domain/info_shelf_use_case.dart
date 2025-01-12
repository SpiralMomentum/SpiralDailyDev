import 'package:dartz/dartz.dart';
import 'package:info_shelf/domain/entity/info.dart';
import 'package:info_shelf/domain/info_shelf_repository.dart';

class Failure {
  final Object? exception;
  final String? message;
  Failure({this.message, this.exception});
}

class InfoShelfUseCase {
  final InfoShelfRepository repository;

  InfoShelfUseCase(this.repository);

  Future<Either<Failure,List<Info>>> fetchInfoList(
      int startIndex,
      int endIndex,
      ) async {
    try {
      final response = await repository.fetchInfo(
        startIndex,
        endIndex,
      );
    return Right(response);
    } catch (e) {
      return Left(Failure(exception: e));
    }
  }
}