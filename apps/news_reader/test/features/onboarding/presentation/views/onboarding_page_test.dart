import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/result/result.dart';

import 'package:apps.news_reader/features/settings/domain/repositories/settings_repository.dart';
import 'package:apps.news_reader/features/onboarding/presentation/views/onboarding_page.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository settingsRepository;
  late bool completedCalled;

  setUp(() {
    settingsRepository = MockSettingsRepository();
    completedCalled = false;
  });

  Widget buildApp() {
    return MaterialApp(
      home: OnboardingPage(
        settingsRepository: settingsRepository,
        onCompleted: () {
          completedCalled = true;
        },
      ),
    );
  }

  group('OnboardingPage', () {
    testWidgets('shows intro page initially with next button',
        (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.text('News Reader'), findsOneWidget);
      expect(find.byIcon(Icons.newspaper), findsOneWidget);
      expect(find.text('\ub2e4\uc74c'), findsOneWidget);
    });

    testWidgets('navigates through pages and validates category minimum',
        (tester) async {
      await tester.pumpWidget(buildApp());

      // Step 1 -> Step 2
      await tester.tap(find.text('\ub2e4\uc74c'));
      await tester.pumpAndSettle();

      expect(find.text('Choose Your Interests'), findsOneWidget);
      expect(find.text('Select at least 3 categories'), findsOneWidget);

      // Next button should be disabled (0 categories selected)
      final nextButton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(nextButton.onPressed, isNull);

      // Select 2 categories - still not enough
      await tester.tap(find.text('technology'));
      await tester.pump();
      await tester.tap(find.text('science'));
      await tester.pump();

      final nextButton2 =
          tester.widget<FilledButton>(find.byType(FilledButton));
      expect(nextButton2.onPressed, isNull);

      // Select a 3rd category - now valid
      await tester.tap(find.text('health'));
      await tester.pump();

      final nextButton3 =
          tester.widget<FilledButton>(find.byType(FilledButton));
      expect(nextButton3.onPressed, isNotNull);
    });

    testWidgets('completes onboarding and calls callbacks', (tester) async {
      when(() => settingsRepository.setOnboardingCompleted(true))
          .thenAnswer((_) async => const Success(null));

      await tester.pumpWidget(buildApp());

      // Step 1 -> Step 2
      await tester.tap(find.text('\ub2e4\uc74c'));
      await tester.pumpAndSettle();

      // Select 3 categories
      await tester.tap(find.text('technology'));
      await tester.pump();
      await tester.tap(find.text('business'));
      await tester.pump();
      await tester.tap(find.text('science'));
      await tester.pump();

      // Step 2 -> Step 3
      await tester.tap(find.text('\ub2e4\uc74c'));
      await tester.pumpAndSettle();

      expect(find.text('Stay Updated'), findsOneWidget);
      expect(find.text('\uc2dc\uc791\ud558\uae30'), findsOneWidget);

      // Complete
      await tester.tap(find.text('\uc2dc\uc791\ud558\uae30'));
      await tester.pumpAndSettle();

      verify(() => settingsRepository.setOnboardingCompleted(true)).called(1);
      expect(completedCalled, isTrue);
    });

    testWidgets('shows page indicator dots for each step', (tester) async {
      await tester.pumpWidget(buildApp());

      // 3 indicator dots
      final containers = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).borderRadius ==
                BorderRadius.circular(4),
      );
      expect(containers, findsNWidgets(3));
    });
  });
}
