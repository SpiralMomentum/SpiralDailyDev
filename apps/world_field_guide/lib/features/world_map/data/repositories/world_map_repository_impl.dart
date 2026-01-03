import 'package:utils/utils.dart';
import 'package:world_field_guide/features/world_map/domain/entities/world_map_data.dart';
import 'package:world_field_guide/features/world_map/domain/repositories/world_map_repository.dart';

class WorldMapRepositoryImpl implements WorldMapRepository {
  const WorldMapRepositoryImpl();

  @override
  Result<WorldMapData> loadStaticMap() {
    return const Success<WorldMapData>(
      WorldMapData(caption: '전 세계 특산품을 한눈에 살펴보세요.'),
    );
  }
}
