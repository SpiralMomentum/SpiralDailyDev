import '../entities/quote_display_preferences.dart';
import '../repositories/quote_repository.dart';

/// Persists delivery preference changes.
class UpdateDisplayPreferences {
  /// Creates [UpdateDisplayPreferences].
  const UpdateDisplayPreferences(this._repository);

  final QuoteRepository _repository;

  /// Stores the provided preferences.
  Future<void> call(QuoteDisplayPreferences preferences) {
    return _repository.updateDisplayPreferences(preferences);
  }
}
