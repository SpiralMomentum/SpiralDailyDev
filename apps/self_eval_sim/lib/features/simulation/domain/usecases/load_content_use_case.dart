import 'package:utils/utils.dart';

import '../entities/catalog.dart';
import '../repositories/content_repository.dart';

class LoadContentUseCase {
  const LoadContentUseCase(this._repository);

  final ContentRepository _repository;

  Future<Result<LocalizedContent>> call(String languageCode) async {
    final catalog = await _repository.loadCatalog();
    if (catalog case ErrorResult(:final failure)) {
      return ErrorResult(failure);
    }
    final text = await _repository.loadText(languageCode);
    return text.map(
      (t) => LocalizedContent(catalog: catalog.dataOrNull!, text: t),
    );
  }
}
