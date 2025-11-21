import '../entities/monster.dart';
import 'sort_monsters_use_case.dart';

class FilterMonstersByCountryUseCase {
  const FilterMonstersByCountryUseCase({
    required SortMonstersUseCase sortMonsters,
  }) : _sortMonsters = sortMonsters;

  final SortMonstersUseCase _sortMonsters;

  List<Monster> call(List<Monster> source, String countryCode) {
    final normalized = countryCode.trim().toUpperCase();
    final filtered = source
        .where((monster) => monster.country.toUpperCase() == normalized)
        .toList();
    return _sortMonsters(filtered);
  }
}
