import 'world_map_data.dart';

class WorldMapRepository {
  const WorldMapRepository();

  WorldMapData loadStaticMap() {
    return const WorldMapData(caption: '전 세계 국가 경계를 한눈에 살펴보세요.');
  }
}
