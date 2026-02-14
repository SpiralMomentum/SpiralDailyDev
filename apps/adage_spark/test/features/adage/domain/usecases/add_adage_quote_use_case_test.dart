import 'package:adage_spark/features/adage/domain/entities/adage_quote.dart';
import 'package:adage_spark/features/adage/domain/repositories/adage_repository.dart';
import 'package:adage_spark/features/adage/domain/usecases/add_adage_quote_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/utils.dart';

class MockAdageRepository extends Mock implements AdageRepository {}

void main() {
  late MockAdageRepository mockRepository;
  late AddAdageQuoteUseCase useCase;

  setUp(() {
    mockRepository = MockAdageRepository();
    useCase = AddAdageQuoteUseCase(repository: mockRepository);
  });

  const tBody = '새로운 격언';
  const tReference = '출처 C';
  const tQuote = AdageQuote(body: tBody, reference: tReference);

  group('AddAdageQuoteUseCase', () {
    test('성공 시 추가된 격언을 반환한다', () async {
      when(() => mockRepository.addCustomQuote(
            body: any(named: 'body'),
            reference: any(named: 'reference'),
          )).thenAnswer((_) async => const Success(tQuote));

      final result = await useCase(body: tBody, reference: tReference);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(tQuote));
      expect(result.dataOrNull!.body, equals(tBody));
      expect(result.dataOrNull!.reference, equals(tReference));
      verify(() => mockRepository.addCustomQuote(
            body: tBody,
            reference: tReference,
          )).called(1);
    });

    test('실패 시 ErrorResult를 반환한다', () async {
      const failure = LocalStorageFailure(message: '저장 실패');
      when(() => mockRepository.addCustomQuote(
            body: any(named: 'body'),
            reference: any(named: 'reference'),
          )).thenAnswer((_) async => const ErrorResult(failure));

      final result = await useCase(body: tBody, reference: tReference);

      expect(result.isError, isTrue);
      expect(result.failureOrNull, isA<LocalStorageFailure>());
      expect(result.failureOrNull!.message, equals('저장 실패'));
    });

    test('repository에 올바른 파라미터를 전달한다', () async {
      when(() => mockRepository.addCustomQuote(
            body: any(named: 'body'),
            reference: any(named: 'reference'),
          )).thenAnswer((_) async => const Success(tQuote));

      await useCase(body: '커스텀 본문', reference: '커스텀 출처');

      verify(() => mockRepository.addCustomQuote(
            body: '커스텀 본문',
            reference: '커스텀 출처',
          )).called(1);
    });

    test('Result.when으로 성공/실패 분기를 처리할 수 있다', () async {
      when(() => mockRepository.addCustomQuote(
            body: any(named: 'body'),
            reference: any(named: 'reference'),
          )).thenAnswer((_) async => const Success(tQuote));

      final result = await useCase(body: tBody, reference: tReference);

      final message = result.when(
        success: (quote) => '성공: ${quote.body}',
        error: (failure) => '실패: ${failure.message}',
      );
      expect(message, equals('성공: 새로운 격언'));
    });
  });
}
