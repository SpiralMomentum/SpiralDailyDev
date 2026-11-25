import 'package:flutter/services.dart';
import 'package:utils/utils.dart';

import 'life_table_parser.dart';

/// `assets/life_tables/life_tables.json`을 읽어 [JsonLifeTable]로 만든다.
class AssetLifeTableRepository {
  AssetLifeTableRepository({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  static const assetPath = 'assets/life_tables/life_tables.json';

  final AssetBundle _bundle;

  Future<Result<JsonLifeTable>> load() async {
    final String json;
    try {
      json = await _bundle.loadString(assetPath);
    } catch (e, st) {
      return ErrorResult(
        ParsingFailure(
          message: 'life table: asset not found',
          cause: e,
          stackTrace: st,
        ),
      );
    }
    return parseLifeTable(json);
  }
}
