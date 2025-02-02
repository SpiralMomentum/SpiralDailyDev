import 'package:ui_components/card/info.dart';

abstract class InfoShelfRepository {
  Future<List<Info>> fetchInfo(
    int startIndex,
    int endIndex,
  );
}
