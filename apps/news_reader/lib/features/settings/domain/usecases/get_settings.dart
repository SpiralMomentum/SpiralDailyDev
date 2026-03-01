import 'package:utils/result/result.dart';

import '../entities/user_preferences.dart';
import '../repositories/settings_repository.dart';

class GetSettings {
  const GetSettings(this._repository);

  final SettingsRepository _repository;

  Future<Result<UserPreferences>> call() {
    return _repository.getSettings();
  }
}
