import 'package:spiral_trade_show/features/info_shelf/domain/info_shelf_repository.dart';
import 'package:ui_components/card/info.dart';
import 'package:utils/utils.dart';

class InfoShelfUseCase {
  final InfoShelfRepository repository;

  InfoShelfUseCase(this.repository);

  Future<Result<List<Info>>> fetchInfoList(
      int startIndex,
      int endIndex,
      ) async {
    return repository.fetchInfo(startIndex, endIndex);
  }
}
