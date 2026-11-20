import 'package:utils/utils.dart';

import '../../domain/entities/catalog.dart';
import '../../domain/entities/text_book.dart';
import '../../domain/repositories/content_repository.dart';
import '../../domain/story/story_world.dart';
import '../datasources/content_asset_data_source.dart';
import '../mappers/catalog_mapper.dart';
import '../story/story_world_mapper.dart';

class ContentRepositoryImpl implements ContentRepository {
  ContentRepositoryImpl(this._source, {this.storyWorlds = const ['wuxia']});

  final ContentAssetDataSource _source;

  /// 문장을 합칠 이야기 세계 id.
  final List<String> storyWorlds;
  ContentCatalog? _catalog;
  final Map<String, StoryWorld> _worlds = {};

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

  /// 기본 문장에 이야기 문장을 합친다. 이야기 문장 파일이 없으면 기본 문장만.
  @override
  Future<Result<TextBook>> loadText(String languageCode) => guardAsync(
        action: () async => CatalogMapper.textBook(languageCode, {
          ...await _source.strings(languageCode),
          for (final w in storyWorlds)
            ...await _source.storyStrings(w, languageCode),
        }),
        onError: (e, st) =>
            ParsingFailure(message: 'strings:$languageCode', cause: e, stackTrace: st),
      );

  @override
  Future<Result<StoryWorld>> loadStoryWorld(String worldId) async {
    final cached = _worlds[worldId];
    if (cached != null) return Success(cached);
    final result = await guardAsync(
      action: () async => StoryWorldMapper.fromJson(await _source.storyWorld(worldId)),
      onError: (e, st) =>
          ParsingFailure(message: 'story:$worldId', cause: e, stackTrace: st),
    );
    if (result.dataOrNull case final world?) _worlds[worldId] = world;
    return result;
  }
}
