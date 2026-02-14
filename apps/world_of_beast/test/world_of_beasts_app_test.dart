import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utils/result/result.dart';
import 'package:world_map_widget/world_map_widget.dart';

import 'package:world_of_beast/features/monsters/domain/entities/monster.dart';
import 'package:world_of_beast/features/monsters/domain/repositories/monster_repository.dart';
import 'package:world_of_beast/main.dart';

class _FakeMonsterRepository implements MonsterRepository {
  _FakeMonsterRepository(this.monsters);

  final List<Monster> monsters;

  @override
  Future<Result<List<Monster>>> fetchMonsters() async {
    return Success(monsters);
  }
}

void main() {
  const testMonsters = [
    Monster(
      id: 'kr-gumiho',
      name: 'Gumiho',
      shortDescription: 'Nine-tailed fox.',
      country: 'KR',
    ),
    Monster(
      id: 'eg-ammit',
      name: 'Ammit',
      shortDescription:
          'Devourer of hearts that are heavier than a feather of Ma\'at.',
      country: 'EG',
    ),
    Monster(
      id: 'mx-chupacabra',
      name: 'Chupacabra',
      shortDescription: 'Goat-sucking creature that prowls rural farmlands.',
      country: 'MX',
    ),
    Monster(
      id: 'cn-dragon',
      name: 'Azure Dragon',
      shortDescription: 'Celestial dragon symbolizing strength and prosperity.',
      country: 'CN',
    ),
    Monster(
      id: 'kr-dokkaebi',
      name: 'Dokkaebi',
      shortDescription:
          'Playful goblin who rewards the worthy and tricks the vain.',
      country: 'KR',
    ),
    Monster(
      id: 'jp-oni',
      name: 'Oni',
      shortDescription:
          'Horned ogre wielding iron clubs, feared as a bringer of storms.',
      country: 'JP',
    ),
  ];

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      WorldOfBeastsApp(repository: _FakeMonsterRepository(testMonsters)),
    );
    await tester.pumpAndSettle();
  }

  List<String> visibleMonsterNames(WidgetTester tester) {
    final nameFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.key is ValueKey<String> &&
          (widget.key as ValueKey<String>).value.startsWith('monsterName_'),
    );
    return tester
        .widgetList<Text>(nameFinder)
        .map((text) => text.data ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
  }

  Future<void> openMapView(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('viewToggleButton')));
    await tester.pumpAndSettle();
  }

  Future<void> selectCountry(
    WidgetTester tester, {
    required String code,
    required String name,
  }) async {
    final mapWidget = tester.widget<WorldMapWidget>(
      find.byType(WorldMapWidget),
    );
    mapWidget.onCountryTap?.call(
      WorldCountryTapDetails(
        countryId: code,
        countryName: name,
        instructions: 'tap',
      ),
    );
    await tester.pumpAndSettle();
  }

  group('List View (F1)', () {
    testWidgets('renders sorted monster list on launch', (tester) async {
      await pumpApp(tester);
      expect(find.byKey(const ValueKey('monsterListView')), findsOneWidget);
      expect(find.text('All Monsters'), findsOneWidget);
    });

    testWidgets('monsters appear in alphabetical order', (tester) async {
      await pumpApp(tester);
      final names = visibleMonsterNames(tester);
      final sortedNames = [...names]..sort((a, b) => a.compareTo(b));
      expect(names, sortedNames);
      expect(names.take(3).toList(), ['Ammit', 'Azure Dragon', 'Chupacabra']);
    });

    testWidgets('cards show only mandatory fields', (tester) async {
      await pumpApp(tester);
      final cardFinder = find.byKey(const ValueKey('monsterCard_eg-ammit'));
      expect(cardFinder, findsOneWidget);
      expect(
        find.descendant(of: cardFinder, matching: find.text('Ammit')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: cardFinder,
          matching: find.text(
            'Devourer of hearts that are heavier than a feather of Ma\'at.',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: cardFinder, matching: find.byType(Image)),
        findsNothing,
      );
    });
  });

  group('View Toggle (F3)', () {
    testWidgets('switches from list to map', (tester) async {
      await pumpApp(tester);
      await openMapView(tester);
      expect(find.byKey(const ValueKey('monsterMapView')), findsOneWidget);
    });

    testWidgets('map to list returns to All Monsters', (tester) async {
      await pumpApp(tester);
      await openMapView(tester);
      await tester.tap(find.byKey(const ValueKey('viewToggleButton')));
      await tester.pumpAndSettle();
      expect(find.text('All Monsters'), findsOneWidget);
    });
  });

  group('Map View (F2)', () {
    testWidgets('selecting a country shows filtered list', (tester) async {
      await pumpApp(tester);
      await openMapView(tester);
      await selectCountry(tester, code: 'KR', name: 'South Korea');
      expect(find.byKey(const ValueKey('mapCountrySheet')), findsOneWidget);
      expect(find.text('South Korea Monsters'), findsOneWidget);
      expect(find.text('Gumiho'), findsOneWidget);
      expect(find.text('Dokkaebi'), findsOneWidget);
      expect(find.text('Ammit'), findsNothing);
    });

    testWidgets('overlay can be dismissed while staying on map', (
      tester,
    ) async {
      await pumpApp(tester);
      await openMapView(tester);
      await selectCountry(tester, code: 'KR', name: 'South Korea');
      await tester.tap(find.byKey(const ValueKey('mapCountrySheetClose')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('mapCountrySheet')), findsNothing);
      expect(find.byKey(const ValueKey('monsterMapView')), findsOneWidget);
    });
  });

  group('Integration (G5)', () {
    testWidgets('full flow from list to filtered list', (tester) async {
      await pumpApp(tester);
      await openMapView(tester);
      await selectCountry(tester, code: 'KR', name: 'South Korea');
      expect(find.byKey(const ValueKey('mapCountrySheet')), findsOneWidget);
      expect(find.text('South Korea Monsters'), findsOneWidget);
      expect(find.text('Gumiho'), findsOneWidget);
      expect(find.text('Dokkaebi'), findsOneWidget);
      expect(find.text('Oni'), findsNothing);
    });

    testWidgets('filtered list keeps alphabetical order', (tester) async {
      await pumpApp(tester);
      await openMapView(tester);
      await selectCountry(tester, code: 'KR', name: 'South Korea');
      final names = visibleMonsterNames(tester);
      expect(names, ['Dokkaebi', 'Gumiho']);
    });
  });
}
