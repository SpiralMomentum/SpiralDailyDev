import '../entities/quote_display_preferences.dart';
import '../repositories/quote_repository.dart';

/// Retrieves the user's delivery preference configuration.
class LoadDisplayPreferences {
  /// Creates [LoadDisplayPreferences].
  const LoadDisplayPreferences(this._repository);

  final QuoteRepository _repository;

  /// Loads the persisted preferences.
  Future<QuoteDisplayPreferences> call() {
    return _repository.getDisplayPreferences();
  }
}
