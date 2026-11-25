import 'package:flutter/services.dart';
import 'package:utils/utils.dart';

import '../domain/tone.dart';
import '../domain/tone_table.dart';

/// `assets/tones/{tone}.json`을 읽어 [ToneTable]로 만든다.
class AssetToneRepository {
  AssetToneRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  Future<Result<ToneTable>> load(ToneId id) async {
    final String json;
    try {
      json = await _bundle.loadString('assets/tones/${id.name}.json');
    } catch (e, st) {
      return ErrorResult(
        ParsingFailure(
          message: 'tone ${id.name}: asset not found',
          cause: e,
          stackTrace: st,
        ),
      );
    }
    return parseToneTable(id, json);
  }
}
