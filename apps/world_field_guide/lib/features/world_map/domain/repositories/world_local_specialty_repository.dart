import 'package:utils/utils.dart';

abstract class WorldLocalSpecialtyRepository {
  const WorldLocalSpecialtyRepository();

  Future<Result<List<String>>> fetchForCountry(String countryCode);
}
