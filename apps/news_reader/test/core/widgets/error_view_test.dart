import 'package:apps.news_reader/core/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utils/result/failure.dart';

void main() {
  Widget buildWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('ErrorView', () {
    testWidgets('shows network error with wifi icon', (tester) async {
      final failure = NetworkFailure(message: 'Connection failed');

      await tester.pumpWidget(buildWidget(ErrorView(failure: failure)));

      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.text('네트워크 오류'), findsOneWidget);
      expect(find.text('네트워크 오류입니다. 연결 상태를 확인해 주세요.'), findsOneWidget);
    });

    testWidgets('shows server error message for timeout', (tester) async {
      final failure = NetworkFailure(message: 'timeout');

      await tester.pumpWidget(buildWidget(ErrorView(failure: failure)));

      expect(find.text('서버 오류입니다. 잠시 후 다시 시도해 주세요.'), findsOneWidget);
    });

    testWidgets('shows local storage error with storage icon', (tester) async {
      final failure = LocalStorageFailure(message: 'DB error');

      await tester.pumpWidget(buildWidget(ErrorView(failure: failure)));

      expect(find.byIcon(Icons.storage), findsOneWidget);
      expect(find.text('저장소 오류'), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry is provided', (tester) async {
      var retried = false;
      final failure = NetworkFailure(message: 'error');

      await tester.pumpWidget(buildWidget(
        ErrorView(failure: failure, onRetry: () => retried = true),
      ));

      expect(find.text('재시도'), findsOneWidget);
      await tester.tap(find.text('재시도'));
      expect(retried, isTrue);
    });

    testWidgets('hides retry button when onRetry is null', (tester) async {
      final failure = NetworkFailure(message: 'error');

      await tester.pumpWidget(buildWidget(ErrorView(failure: failure)));

      expect(find.text('재시도'), findsNothing);
    });

    testWidgets('compact mode shows inline layout', (tester) async {
      final failure = NetworkFailure(message: 'error');

      await tester.pumpWidget(buildWidget(
        ErrorView(failure: failure, compact: true, onRetry: () {}),
      ));

      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });

  group('EmptyView', () {
    testWidgets('shows icon and message', (tester) async {
      await tester.pumpWidget(buildWidget(
        const EmptyView(
          icon: Icons.bookmark_border,
          message: '저장한 기사가 없습니다.',
        ),
      ));

      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
      expect(find.text('저장한 기사가 없습니다.'), findsOneWidget);
    });

    testWidgets('shows action widget when provided', (tester) async {
      await tester.pumpWidget(buildWidget(
        EmptyView(
          icon: Icons.search,
          message: '검색 결과가 없습니다.',
          action: ElevatedButton(
            onPressed: () {},
            child: const Text('다시 검색'),
          ),
        ),
      ));

      expect(find.text('다시 검색'), findsOneWidget);
    });
  });
}
