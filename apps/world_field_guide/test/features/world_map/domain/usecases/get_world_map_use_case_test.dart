import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/utils.dart';
import 'package:world_field_guide/features/world_map/domain/entities/world_map_data.dart';
import 'package:world_field_guide/features/world_map/domain/repositories/world_map_repository.dart';
import 'package:world_field_guide/features/world_map/domain/usecases/get_world_map_use_case.dart';

class MockWorldMapRepository extends Mock implements WorldMapRepository {}

void main() {
  late MockWorldMapRepository mockRepository;
  late GetWorldMapUseCase useCase;

  setUp(() {
    mockRepository = MockWorldMapRepository();
    useCase = GetWorldMapUseCase(repository: mockRepository);
  });

  group('GetWorldMapUseCase', () {
    test('성공 시 Success<WorldMapData>를 반환한다', () {
      // arrange
      const expected = WorldMapData(caption: '테스트 캡션');
      when(() => mockRepository.loadStaticMap())
          .thenReturn(const Success<WorldMapData>(expected));

      // act
      final result = useCase.call();

      // assert
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(expected));
      expect(result.dataOrNull?.caption, equals('테스트 캡션'));
      verify(() => mockRepository.loadStaticMap()).called(1);
    });

    test('Repository가 ErrorResult를 반환하면 그대로 전파된다', () {
      // arrange
      const failure = ParsingFailure(message: '맵 로드 실패');
      when(() => mockRepository.loadStaticMap())
          .thenReturn(const ErrorResult<WorldMapData>(failure));

      // act
      final result = useCase.call();

      // assert
      expect(result.isError, isTrue);
      expect(result.failureOrNull, isA<ParsingFailure>());
      expect(result.failureOrNull?.message, equals('맵 로드 실패'));
    });

    test('Repository의 loadStaticMap을 정확히 1회 호출한다', () {
      // arrange
      const data = WorldMapData(caption: '캡션');
      when(() => mockRepository.loadStaticMap())
          .thenReturn(const Success<WorldMapData>(data));

      // act
      useCase.call();

      // assert
      verify(() => mockRepository.loadStaticMap()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
