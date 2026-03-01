import 'package:utils/result/result.dart';

import '../entities/user_preferences.dart';
import '../repositories/settings_repository.dart';

class UpdateSettings {
  const UpdateSettings(this._repository);

  final SettingsRepository _repository;

  Future<Result<void>> call(UserPreferences preferences) {
    return _repository.updateSettings(preferences);
  }
}
