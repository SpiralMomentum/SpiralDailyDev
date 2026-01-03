import 'package:world_field_guide/features/world_map/domain/entities/world_map_data.dart';
import 'package:world_field_guide/features/world_map/domain/repositories/world_map_repository.dart';
import 'package:utils/utils.dart';

class GetWorldMapUseCase {
  const GetWorldMapUseCase({required WorldMapRepository repository})
      : _repository = repository;

  final WorldMapRepository _repository;

  Result<WorldMapData> call() => _repository.loadStaticMap();
}
