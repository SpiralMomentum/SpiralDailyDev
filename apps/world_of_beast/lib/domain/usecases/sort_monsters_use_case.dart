import '../entities/monster.dart';

class SortMonstersUseCase {
  const SortMonstersUseCase();

  List<Monster> call(List<Monster> monsters) {
    final sorted = [...monsters];
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return sorted;
  }
}
