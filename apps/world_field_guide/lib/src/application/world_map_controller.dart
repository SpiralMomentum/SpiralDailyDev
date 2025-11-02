import '../domain/world_map_data.dart';
import '../domain/world_map_repository.dart';

class WorldMapController {
  WorldMapController({WorldMapRepository? repository})
    : _repository = repository ?? const WorldMapRepository();

  final WorldMapRepository _repository;

  WorldMapData get worldMap => _repository.loadStaticMap();
}
