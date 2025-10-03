import 'package:flutter/services.dart';

import '../../domain/repositories/clipboard_repository.dart';

class ClipboardRepositoryImpl implements ClipboardRepository {
  @override
  Future<void> copy(String value) {
    return Clipboard.setData(ClipboardData(text: value));
  }
}
