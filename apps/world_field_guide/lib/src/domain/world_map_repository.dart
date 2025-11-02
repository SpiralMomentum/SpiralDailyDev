import 'world_map_data.dart';

class WorldMapRepository {
  const WorldMapRepository();

  WorldMapData loadStaticMap() {
    return const WorldMapData(caption: '전 세계 특산품을 한눈에 살펴보세요.');
  }
}
