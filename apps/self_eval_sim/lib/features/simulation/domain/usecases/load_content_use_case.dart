import 'package:utils/utils.dart';

import '../entities/catalog.dart';
import '../repositories/content_repository.dart';

class LoadContentUseCase {
  const LoadContentUseCase(this._repository);

  /// 함께 싣는 이야기 세계. 불러오지 못하면 빠지고 그 채널은 기존 시행 흐름으로 동작한다.
  static const storyWorlds = ['wuxia'];

  final ContentRepository _repository;

  Future<Result<LocalizedContent>> call(String languageCode) async {
    final catalog = await _repository.loadCatalog();
    if (catalog case ErrorResult(:final failure)) {
      return ErrorResult(failure);
    }
    final text = await _repository.loadText(languageCode);
    if (text case ErrorResult(:final failure)) {
      return ErrorResult(failure);
    }
    final stories = {
      for (final id in storyWorlds)
        id: ?(await _repository.loadStoryWorld(id)).dataOrNull,
    };
    return Success(
      LocalizedContent(
        catalog: catalog.dataOrNull!,
        text: text.dataOrNull!,
        stories: stories,
      ),
    );
  }
}
