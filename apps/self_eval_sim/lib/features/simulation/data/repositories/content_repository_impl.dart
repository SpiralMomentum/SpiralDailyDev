import 'package:utils/utils.dart';

import '../../domain/entities/catalog.dart';
import '../../domain/entities/text_book.dart';
import '../../domain/repositories/content_repository.dart';
import '../datasources/content_asset_data_source.dart';
import '../mappers/catalog_mapper.dart';

class ContentRepositoryImpl implements ContentRepository {
  ContentRepositoryImpl(this._source);

  final ContentAssetDataSource _source;
  ContentCatalog? _catalog;

  @override
  Future<Result<ContentCatalog>> loadCatalog() async {
    final cached = _catalog;
    if (cached != null) return Success(cached);
    final result = await guardAsync(
      action: () async => CatalogMapper.catalog(await _source.structure()),
      onError: (e, st) => ParsingFailure(message: 'catalog', cause: e, stackTrace: st),
    );
    _catalog = result.dataOrNull;
    return result;
  }

  @override
  Future<Result<TextBook>> loadText(String languageCode) => guardAsync(
        action: () async =>
            CatalogMapper.textBook(languageCode, await _source.strings(languageCode)),
        onError: (e, st) =>
            ParsingFailure(message: 'strings:$languageCode', cause: e, stackTrace: st),
      );
}
