import 'package:info_shelf/domain/entity/info.dart';

abstract class InfoShelfRepository {
  Future<List<Info>> fetchInfo(
    int startIndex,
    int endIndex,
  );
}
