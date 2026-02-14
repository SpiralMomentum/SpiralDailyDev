import 'package:adage_spark/features/adage/data/datasources/adage_local_data_source.dart';
import 'package:adage_spark/features/adage/data/models/adage_quote_dto.dart';
import 'package:adage_spark/features/adage/data/repositories/adage_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/utils.dart';

class MockAdageLocalDataSource extends Mock implements AdageLocalDataSource {}

void main() {
  late MockAdageLocalDataSource mockDataSource;
  late AdageRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockAdageLocalDataSource();
    repository = AdageRepositoryImpl(localDataSource: mockDataSource);
  });

  setUpAll(() {
    registerFallbackValue(
      const AdageQuoteDto(body: 'fallback', reference: 'fallback'),
    );
  });

  final tDtos = [
    const AdageQuoteDto(body: '격언 1', reference: '출처 1'),
    const AdageQuoteDto(body: '격언 2', reference: '출처 2'),
  ];

  group('fetchQuotes', () {
    test('성공 시 DTO를 도메인 엔티티로 변환하여 반환한다', () async {
      when(() => mockDataSource.fetchQuotes()).thenReturn(Success(tDtos));

      final result = await repository.fetchQuotes();

      expect(result.isSuccess, isTrue);
      final quotes = result.dataOrNull!;
      expect(quotes.length, equals(2));
      expect(quotes[0].body, equals('격언 1'));
      expect(quotes[0].reference, equals('출처 1'));
      expect(quotes[1].body, equals('격언 2'));
      verify(() => mockDataSource.fetchQuotes()).called(1);
    });

    test('실패 시 ErrorResult를 그대로 전파한다', () async {
      const failure = LocalStorageFailure(message: '로컬 데이터 오류');
      when(() => mockDataSource.fetchQuotes())
          .thenReturn(const ErrorResult(failure));

      final result = await repository.fetchQuotes();

      expect(result.isError, isTrue);
      expect(result.failureOrNull, isA<LocalStorageFailure>());
      expect(result.failureOrNull!.message, equals('로컬 데이터 오류'));
    });

    test('빈 목록일 때도 Success를 반환한다', () async {
      when(() => mockDataSource.fetchQuotes())
          .thenReturn(const Success([]));

      final result = await repository.fetchQuotes();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isEmpty);
    });
  });

  group('addCustomQuote', () {
    const tDto = AdageQuoteDto(body: '새 격언', reference: '새 출처');

    test('성공 시 추가된 격언을 도메인 엔티티로 변환하여 반환한다', () async {
      when(() => mockDataSource.addCustomQuote(any()))
          .thenReturn(const Success(tDto));

      final result = await repository.addCustomQuote(
        body: '새 격언',
        reference: '새 출처',
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull!.body, equals('새 격언'));
      expect(result.dataOrNull!.reference, equals('새 출처'));
      verify(() => mockDataSource.addCustomQuote(any())).called(1);
    });

    test('실패 시 ErrorResult를 그대로 전파한다', () async {
      const failure = LocalStorageFailure(message: '저장소 오류');
      when(() => mockDataSource.addCustomQuote(any()))
          .thenReturn(const ErrorResult(failure));

      final result = await repository.addCustomQuote(
        body: '새 격언',
        reference: '새 출처',
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull!.message, equals('저장소 오류'));
    });

    test('DataSource에 올바른 DTO를 전달한다', () async {
      when(() => mockDataSource.addCustomQuote(any()))
          .thenReturn(const Success(tDto));

      await repository.addCustomQuote(
        body: '새 격언',
        reference: '새 출처',
      );

      final captured = verify(
        () => mockDataSource.addCustomQuote(captureAny()),
      ).captured.single as AdageQuoteDto;
      expect(captured.body, equals('새 격언'));
      expect(captured.reference, equals('새 출처'));
    });
  });
}
