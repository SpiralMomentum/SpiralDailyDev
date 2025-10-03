import '../repositories/clipboard_repository.dart';

class CopyToClipboardUseCase {
  const CopyToClipboardUseCase(this._clipboardRepository);

  final ClipboardRepository _clipboardRepository;

  Future<void> call(String value) {
    return _clipboardRepository.copy(value);
  }
}
