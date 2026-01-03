import 'package:world_field_guide/features/world_map/domain/entities/world_map_data.dart';
import 'package:utils/utils.dart';

abstract class WorldMapRepository {
  const WorldMapRepository();

  Result<WorldMapData> loadStaticMap();
}
