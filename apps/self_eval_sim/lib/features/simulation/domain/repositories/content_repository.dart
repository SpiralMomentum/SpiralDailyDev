import 'package:utils/utils.dart';

import '../entities/catalog.dart';
import '../entities/text_book.dart';

abstract interface class ContentRepository {
  Future<Result<ContentCatalog>> loadCatalog();
  Future<Result<TextBook>> loadText(String languageCode);
}
