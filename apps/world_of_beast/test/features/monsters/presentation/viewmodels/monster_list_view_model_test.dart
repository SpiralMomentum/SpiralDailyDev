import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/result/failure.dart';
import 'package:utils/result/result.dart';

import 'package:world_of_beast/features/monsters/domain/entities/monster.dart';
import 'package:world_of_beast/features/monsters/domain/repositories/monster_repository.dart';
import 'package:world_of_beast/features/monsters/domain/usecases/filter_monsters_by_country_use_case.dart';
import 'package:world_of_beast/features/monsters/domain/usecases/get_monsters_use_case.dart';
import 'package:world_of_beast/features/monsters/domain/usecases/sort_monsters_use_case.dart';
import 'package:world_of_beast/features/monsters/presentation/viewmodels/monster_list_view_model.dart';

class MockMonsterRepository extends Mock implements MonsterRepository {}

void main() {
  const sampleMonsters = [
    Monster(
      id: 'kr_0',
      name: 'Gumiho',
      shortDescription: 'Nine-tailed fox.',
      country: 'KR',
    ),
    Monster(
      id: 'kr_1',
      name: 'Dokkaebi',
      shortDescription: 'Playful goblin.',
      country: 'KR',
    ),
    Monster(
      id: 'jp_0',
      name: 'Kappa',
      shortDescription: 'River spirit.',
      country: 'JP',
    ),
  ];

  late MockMonsterRepository mockRepository;
  late MonsterListViewModel viewModel;

  setUp(() {
    mockRepository = MockMonsterRepository();
    const sortUseCase = SortMonstersUseCase();
    viewModel = MonsterListViewModel(
      getMonsters: GetMonstersUseCase(
        repository: mockRepository,
        sortMonsters: sortUseCase,
      ),
      filterByCountry: const FilterMonstersByCountryUseCase(
        sortMonsters: sortUseCase,
      ),
    );
  });

  tearDown(() {
    viewModel.dispose();
  });

  group('MonsterListViewModel', () {
    test('initial state: not loading, no error, list view mode', () {
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.viewMode, ViewMode.list);
      expect(viewModel.allMonsters, isEmpty);
    });

    test('loadMonsters transitions loading -> loaded with sorted data',
        () async {
      when(() => mockRepository.fetchMonsters())
          .thenAnswer((_) async => const Success(sampleMonsters));

      final states = <bool>[];
      viewModel.addListener(() {
        states.add(viewModel.isLoading);
      });

      await viewModel.loadMonsters();

      // First notification: isLoading = true
      // Second notification: isLoading = false (loaded)
      expect(states, [true, false]);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.allMonsters, hasLength(3));
      // Sorted alphabetically: Dokkaebi, Gumiho, Kappa
      expect(viewModel.allMonsters[0].name, 'Dokkaebi');
      expect(viewModel.allMonsters[1].name, 'Gumiho');
      expect(viewModel.allMonsters[2].name, 'Kappa');
    });

    test('loadMonsters sets errorMessage on failure', () async {
      when(() => mockRepository.fetchMonsters()).thenAnswer(
        (_) async => const ErrorResult(
          ParsingFailure(message: 'Test error'),
        ),
      );

      await viewModel.loadMonsters();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, 'Test error');
      expect(viewModel.allMonsters, isEmpty);
    });

    test('toggleViewMode switches between list and map', () async {
      when(() => mockRepository.fetchMonsters())
          .thenAnswer((_) async => const Success(sampleMonsters));
      await viewModel.loadMonsters();

      expect(viewModel.viewMode, ViewMode.list);

      viewModel.toggleViewMode();
      expect(viewModel.viewMode, ViewMode.map);

      viewModel.toggleViewMode();
      expect(viewModel.viewMode, ViewMode.list);
    });

    test('toggleViewMode does nothing when loading', () {
      // viewModel hasn't loaded yet, canToggleView depends on no error and not loading
      // Default state: isLoading = false, errorMessage = null, so canToggleView = true
      // We need to set isLoading state: start loading but don't await
      when(() => mockRepository.fetchMonsters()).thenAnswer(
        (_) => Future.delayed(
          const Duration(seconds: 10),
          () => const Success(sampleMonsters),
        ),
      );
      viewModel.loadMonsters(); // don't await - isLoading becomes true

      viewModel.toggleViewMode();
      expect(viewModel.viewMode, ViewMode.list);
    });

    test('monstersForCountry returns filtered monsters for valid country',
        () async {
      when(() => mockRepository.fetchMonsters())
          .thenAnswer((_) async => const Success(sampleMonsters));
      await viewModel.loadMonsters();

      final krMonsters = viewModel.monstersForCountry('KR');

      expect(krMonsters, hasLength(2));
      expect(krMonsters.every((m) => m.country == 'KR'), isTrue);
      // Sorted: Dokkaebi, Gumiho
      expect(krMonsters[0].name, 'Dokkaebi');
      expect(krMonsters[1].name, 'Gumiho');
    });

    test('monstersForCountry returns empty list for unknown country', () async {
      when(() => mockRepository.fetchMonsters())
          .thenAnswer((_) async => const Success(sampleMonsters));
      await viewModel.loadMonsters();

      final result = viewModel.monstersForCountry('BR');

      expect(result, isEmpty);
    });

    test('availableCountries is populated after loading', () async {
      when(() => mockRepository.fetchMonsters())
          .thenAnswer((_) async => const Success(sampleMonsters));
      await viewModel.loadMonsters();

      expect(viewModel.availableCountries, containsAll(['KR', 'JP']));
      expect(viewModel.availableCountries, hasLength(2));
    });
  });
}
