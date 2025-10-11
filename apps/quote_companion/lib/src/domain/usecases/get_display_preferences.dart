import '../entities/quote_display_preferences.dart';
import '../repositories/quote_repository.dart';

/// Loads saved display preferences.
class GetDisplayPreferences {
  /// Creates [GetDisplayPreferences].
  const GetDisplayPreferences(this._repository);

  final QuoteRepository _repository;

  /// Executes the use-case.
  Future<QuoteDisplayPreferences> call() =>
      _repository.getDisplayPreferences();
}
