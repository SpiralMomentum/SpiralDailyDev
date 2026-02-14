import 'package:adage_spark/features/adage/domain/entities/adage_quote.dart';
import 'package:adage_spark/features/adage/domain/usecases/add_adage_quote_use_case.dart';
import 'package:adage_spark/features/adage/domain/usecases/get_adage_quotes_use_case.dart';
import 'package:adage_spark/features/adage/presentation/adage_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/utils.dart';

class MockGetAdageQuotesUseCase extends Mock
    implements GetAdageQuotesUseCase {}

class MockAddAdageQuoteUseCase extends Mock implements AddAdageQuoteUseCase {}

void main() {
  late MockGetAdageQuotesUseCase mockGetUseCase;
  late MockAddAdageQuoteUseCase mockAddUseCase;
  late AdageController controller;

  setUp(() {
    mockGetUseCase = MockGetAdageQuotesUseCase();
    mockAddUseCase = MockAddAdageQuoteUseCase();
    controller = AdageController(
      getAdageQuotesUseCase: mockGetUseCase,
      addAdageQuoteUseCase: mockAddUseCase,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  const tQuotes = [
    AdageQuote(body: '격언 1', reference: '출처 1'),
    AdageQuote(body: '격언 2', reference: '출처 2'),
    AdageQuote(body: '격언 3', reference: '출처 3'),
  ];

  group('초기 상태', () {
    test('initial 상태로 시작한다', () {
      expect(controller.state.quotes, isEmpty);
      expect(controller.state.current, isNull);
      expect(controller.state.errorMessage, isNull);
    });
  });

  group('load()', () {
    test('성공 시 격언 목록과 첫 번째 격언을 현재 상태로 설정한다', () async {
      when(() => mockGetUseCase()).thenAnswer(
        (_) async => const Success(tQuotes),
      );

      await controller.load();

      expect(controller.state.quotes.length, equals(3));
      expect(controller.state.current, equals(tQuotes.first));
      expect(controller.state.errorMessage, isNull);
    });

    test('실패 시 에러 메시지를 상태에 설정한다', () async {
      const failure = LocalStorageFailure(message: '로드 실패');
      when(() => mockGetUseCase()).thenAnswer(
        (_) async => const ErrorResult(failure),
      );

      await controller.load();

      expect(controller.state.quotes, isEmpty);
      expect(controller.state.current, isNull);
      expect(controller.state.errorMessage, equals('로드 실패'));
    });

    test('실패 시 failure.message가 null이면 기본 메시지를 사용한다', () async {
      const failure = LocalStorageFailure();
      when(() => mockGetUseCase()).thenAnswer(
        (_) async => const ErrorResult(failure),
      );

      await controller.load();

      expect(controller.state.errorMessage, equals('격언을 불러오지 못했습니다.'));
    });

    test('notifyListeners를 호출한다', () async {
      when(() => mockGetUseCase()).thenAnswer(
        (_) async => const Success(tQuotes),
      );

      var notified = false;
      controller.addListener(() => notified = true);

      await controller.load();

      expect(notified, isTrue);
    });

    test('빈 목록 성공 시 current가 null이다', () async {
      when(() => mockGetUseCase()).thenAnswer(
        (_) async => const Success(<AdageQuote>[]),
      );

      await controller.load();

      expect(controller.state.quotes, isEmpty);
      expect(controller.state.current, isNull);
    });
  });

  group('showNextQuote()', () {
    test('다음 격언을 표시한다 (현재와 다른 격언)', () async {
      when(() => mockGetUseCase()).thenAnswer(
        (_) async => const Success(tQuotes),
      );
      await controller.load();

      final before = controller.state.current;
      // 격언이 3개이므로 충분한 횟수를 시도하면 다른 격언이 나와야 한다
      var changed = false;
      for (var i = 0; i < 20; i++) {
        controller.showNextQuote();
        if (!identical(controller.state.current, before)) {
          changed = true;
          break;
        }
      }

      expect(changed, isTrue);
    });

    test('current가 null이면 아무 동작하지 않는다', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.showNextQuote();

      expect(notified, isFalse);
      expect(controller.state.current, isNull);
    });

    test('격언이 1개뿐이면 canShuffle=false로 아무 동작하지 않는다', () async {
      const singleQuotes = [
        AdageQuote(body: '유일한 격언', reference: '출처'),
      ];
      when(() => mockGetUseCase()).thenAnswer(
        (_) async => const Success(singleQuotes),
      );
      await controller.load();

      var notifiedAfterLoad = false;
      controller.addListener(() => notifiedAfterLoad = true);

      controller.showNextQuote();

      expect(notifiedAfterLoad, isFalse);
      expect(controller.state.current!.body, equals('유일한 격언'));
    });

    test('showNextQuote 호출 시 notifyListeners가 호출된다', () async {
      when(() => mockGetUseCase()).thenAnswer(
        (_) async => const Success(tQuotes),
      );
      await controller.load();

      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.showNextQuote();

      expect(notifyCount, equals(1));
    });
  });

  group('addQuote()', () {
    const tNewQuote = AdageQuote(body: '새 격언', reference: '새 출처');

    test('성공 시 격언 목록에 추가하고 현재 격언으로 설정한다', () async {
      when(() => mockGetUseCase()).thenAnswer(
        (_) async => const Success(tQuotes),
      );
      await controller.load();

      when(() => mockAddUseCase(
            body: any(named: 'body'),
            reference: any(named: 'reference'),
          )).thenAnswer((_) async => const Success(tNewQuote));

      await controller.addQuote(body: '새 격언', reference: '새 출처');

      expect(controller.state.quotes.length, equals(4));
      expect(controller.state.quotes.first, equals(tNewQuote));
      expect(controller.state.current, equals(tNewQuote));
      expect(controller.state.errorMessage, isNull);
    });

    test('실패 시 기존 상태를 유지하고 에러 메시지를 설정한다', () async {
      when(() => mockGetUseCase()).thenAnswer(
        (_) async => const Success(tQuotes),
      );
      await controller.load();

      const failure = LocalStorageFailure(message: '저장 실패');
      when(() => mockAddUseCase(
            body: any(named: 'body'),
            reference: any(named: 'reference'),
          )).thenAnswer((_) async => const ErrorResult(failure));

      await controller.addQuote(body: '새 격언', reference: '새 출처');

      expect(controller.state.quotes.length, equals(3));
      expect(controller.state.current, equals(tQuotes.first));
      expect(controller.state.errorMessage, equals('저장 실패'));
    });

    test('실패 시 failure.message가 null이면 기본 메시지를 사용한다', () async {
      when(() => mockGetUseCase()).thenAnswer(
        (_) async => const Success(tQuotes),
      );
      await controller.load();

      const failure = LocalStorageFailure();
      when(() => mockAddUseCase(
            body: any(named: 'body'),
            reference: any(named: 'reference'),
          )).thenAnswer((_) async => const ErrorResult(failure));

      await controller.addQuote(body: '새 격언', reference: '새 출처');

      expect(controller.state.errorMessage, equals('격언을 저장하지 못했습니다.'));
    });

    test('addQuote 호출 시 notifyListeners가 호출된다', () async {
      when(() => mockGetUseCase()).thenAnswer(
        (_) async => const Success(tQuotes),
      );
      await controller.load();

      when(() => mockAddUseCase(
            body: any(named: 'body'),
            reference: any(named: 'reference'),
          )).thenAnswer((_) async => const Success(tNewQuote));

      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.addQuote(body: '새 격언', reference: '새 출처');

      expect(notifyCount, equals(1));
    });
  });
}
