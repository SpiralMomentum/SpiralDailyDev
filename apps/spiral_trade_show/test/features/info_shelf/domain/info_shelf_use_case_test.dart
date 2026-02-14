import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spiral_trade_show/features/info_shelf/domain/info_shelf_repository.dart';
import 'package:spiral_trade_show/features/info_shelf/domain/info_shelf_use_case.dart';
import 'package:ui_components/card/info.dart';
import 'package:utils/utils.dart';

class MockInfoShelfRepository extends Mock implements InfoShelfRepository {}

void main() {
  late MockInfoShelfRepository mockRepository;
  late InfoShelfUseCase useCase;

  final testInfoList = [
    Info('title1', 'thumb1', 'place1', 'desc1', DateTime(2024, 1, 1),
        DateTime(2024, 1, 31)),
  ];

  setUp(() {
    mockRepository = MockInfoShelfRepository();
    useCase = InfoShelfUseCase(mockRepository);
  });

  group('InfoShelfUseCase', () {
    test('fetchInfoList는 repository.fetchInfo를 올바른 인자로 호출한다', () async {
      when(() => mockRepository.fetchInfo(0, 30))
          .thenAnswer((_) async => Success(testInfoList));

      await useCase.fetchInfoList(0, 30);

      verify(() => mockRepository.fetchInfo(0, 30)).called(1);
    });

    test('repository가 Success를 반환하면 그대로 전달한다', () async {
      when(() => mockRepository.fetchInfo(0, 30))
          .thenAnswer((_) async => Success(testInfoList));

      final result = await useCase.fetchInfoList(0, 30);

      expect(result.isSuccess, isTrue);
      expect((result as Success<List<Info>>).data, testInfoList);
    });

    test('repository가 ErrorResult를 반환하면 그대로 전달한다', () async {
      const failure = NetworkFailure(message: 'network error');
      when(() => mockRepository.fetchInfo(0, 30))
          .thenAnswer((_) async => const ErrorResult(failure));

      final result = await useCase.fetchInfoList(0, 30);

      expect(result.isError, isTrue);
      expect(
        (result as ErrorResult<List<Info>>).failure,
        isA<NetworkFailure>(),
      );
    });

    test('다른 startIndex, endIndex로 호출해도 repository에 정확히 전달한다', () async {
      when(() => mockRepository.fetchInfo(30, 60))
          .thenAnswer((_) async => Success(testInfoList));

      await useCase.fetchInfoList(30, 60);

      verify(() => mockRepository.fetchInfo(30, 60)).called(1);
      verifyNever(() => mockRepository.fetchInfo(0, 30));
    });
  });
}
