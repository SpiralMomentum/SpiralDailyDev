import '../entities/quote_display_preferences.dart';
import '../repositories/quote_repository.dart';

/// Persists display preferences.
class SaveDisplayPreferences {
  /// Creates [SaveDisplayPreferences].
  const SaveDisplayPreferences(this._repository);

  final QuoteRepository _repository;

  /// Executes the use-case.
  Future<void> call(QuoteDisplayPreferences preferences) {
    return _repository.saveDisplayPreferences(preferences);
  }
}
