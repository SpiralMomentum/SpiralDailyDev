import 'package:utils/utils.dart';

import '../entities/catalog.dart';
import '../entities/text_book.dart';
import '../story/story_world.dart';

abstract interface class ContentRepository {
  Future<Result<ContentCatalog>> loadCatalog();

  /// 언어 문장. 이야기 문장이 있으면 함께 합쳐 돌려준다.
  Future<Result<TextBook>> loadText(String languageCode);

  /// 이야기 세계 정의 (캐시).
  Future<Result<StoryWorld>> loadStoryWorld(String worldId);
}
