import 'package:ui_components/card/info.dart';
import 'package:utils/utils.dart';

abstract class InfoShelfRepository {
  Future<Result<List<Info>>> fetchInfo(
    int startIndex,
    int endIndex,
  );
}
