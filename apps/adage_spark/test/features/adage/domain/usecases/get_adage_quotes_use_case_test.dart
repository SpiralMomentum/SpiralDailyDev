import 'package:adage_spark/features/adage/domain/entities/adage_quote.dart';
import 'package:adage_spark/features/adage/domain/repositories/adage_repository.dart';
import 'package:adage_spark/features/adage/domain/usecases/get_adage_quotes_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/utils.dart';

class MockAdageRepository extends Mock implements AdageRepository {}

void main() {
  late MockAdageRepository mockRepository;
  late GetAdageQuotesUseCase useCase;

  setUp(() {
    mockRepository = MockAdageRepository();
    useCase = GetAdageQuotesUseCase(repository: mockRepository);
  });

  final tQuotes = [
    const AdageQuote(body: '첫 번째 격언', reference: '출처 A'),
    const AdageQuote(body: '두 번째 격언', reference: '출처 B'),
  ];

  group('GetAdageQuotesUseCase', () {
    test('성공 시 격언 목록을 반환한다', () async {
      when(() => mockRepository.fetchQuotes())
          .thenAnswer((_) async => Success(tQuotes));

      final result = await useCase();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(tQuotes));
      expect(result.dataOrNull!.length, equals(2));
      verify(() => mockRepository.fetchQuotes()).called(1);
    });

    test('실패 시 ErrorResult를 반환한다', () async {
      const failure = LocalStorageFailure(message: '데이터 로드 실패');
      when(() => mockRepository.fetchQuotes())
          .thenAnswer((_) async => const ErrorResult(failure));

      final result = await useCase();

      expect(result.isError, isTrue);
      expect(result.failureOrNull, isA<LocalStorageFailure>());
      expect(result.failureOrNull!.message, equals('데이터 로드 실패'));
      verify(() => mockRepository.fetchQuotes()).called(1);
    });

    test('빈 목록도 Success로 반환한다', () async {
      when(() => mockRepository.fetchQuotes())
          .thenAnswer((_) async => const Success([]));

      final result = await useCase();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isEmpty);
    });

    test('Result 타입이 sealed class 패턴에 부합한다', () async {
      when(() => mockRepository.fetchQuotes())
          .thenAnswer((_) async => Success(tQuotes));

      final result = await useCase();

      result.when(
        success: (quotes) {
          expect(quotes, equals(tQuotes));
        },
        error: (failure) {
          fail('Success인데 error 분기로 진입함');
        },
      );
    });
  });
}
