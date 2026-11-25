import '../../balance/domain/profile.dart';
import 'settings.dart';

abstract interface class ProfileRepository {
  Future<Profile?> loadProfile();
  Future<void> saveProfile(Profile p);
  Future<AppSettings> loadSettings();
  Future<void> saveSettings(AppSettings s);
}
