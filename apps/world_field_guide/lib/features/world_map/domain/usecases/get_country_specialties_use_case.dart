import 'package:utils/utils.dart';
import 'package:world_field_guide/features/world_map/domain/repositories/world_local_specialty_repository.dart';

class GetCountrySpecialtiesUseCase {
  const GetCountrySpecialtiesUseCase({
    required WorldLocalSpecialtyRepository repository,
  }) : _repository = repository;

  final WorldLocalSpecialtyRepository _repository;

  Future<Result<List<String>>> call(String countryCode) {
    return _repository.fetchForCountry(countryCode);
  }
}
