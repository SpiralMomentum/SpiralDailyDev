import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/utils.dart';
import 'package:world_field_guide/features/world_map/domain/repositories/world_local_specialty_repository.dart';
import 'package:world_field_guide/features/world_map/domain/usecases/get_country_specialties_use_case.dart';

class MockWorldLocalSpecialtyRepository extends Mock
    implements WorldLocalSpecialtyRepository {}

void main() {
  late MockWorldLocalSpecialtyRepository mockRepository;
  late GetCountrySpecialtiesUseCase useCase;

  setUp(() {
    mockRepository = MockWorldLocalSpecialtyRepository();
    useCase = GetCountrySpecialtiesUseCase(repository: mockRepository);
  });

  group('GetCountrySpecialtiesUseCase', () {
    test('존재하는 국가 코드 조회 시 특산품 리스트를 반환한다', () async {
      // arrange
      const specialties = ['김치', '불고기', '비빔밥'];
      when(() => mockRepository.fetchForCountry('kr'))
          .thenAnswer((_) async => const Success<List<String>>(specialties));

      // act
      final result = await useCase.call('kr');

      // assert
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(specialties));
      expect(result.dataOrNull?.length, equals(3));
      verify(() => mockRepository.fetchForCountry('kr')).called(1);
    });

    test('미존재 국가 코드 조회 시 빈 리스트를 반환한다', () async {
      // arrange
      when(() => mockRepository.fetchForCountry('zz'))
          .thenAnswer((_) async => const Success<List<String>>([]));

      // act
      final result = await useCase.call('zz');

      // assert
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isEmpty);
    });

    test('Repository 실패 시 에러가 전파된다', () async {
      // arrange
      const failure = ParsingFailure(message: '파싱 실패');
      when(() => mockRepository.fetchForCountry('kr'))
          .thenAnswer((_) async => const ErrorResult<List<String>>(failure));

      // act
      final result = await useCase.call('kr');

      // assert
      expect(result.isError, isTrue);
      expect(result.failureOrNull, isA<ParsingFailure>());
      expect(result.failureOrNull?.message, equals('파싱 실패'));
    });

    test('국가 코드를 그대로 Repository에 전달한다', () async {
      // arrange
      when(() => mockRepository.fetchForCountry(any()))
          .thenAnswer((_) async => const Success<List<String>>([]));

      // act
      await useCase.call('JP');

      // assert
      verify(() => mockRepository.fetchForCountry('JP')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
