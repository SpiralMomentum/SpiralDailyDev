import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utils/utils.dart';
import 'package:world_field_guide/features/world_map/data/repositories/world_local_specialty_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const defaultPath =
      'lib/features/world_map/data/world_local_specialty.json';

  final testJsonData = {
    'kr': ['김치', '불고기', '비빔밥'],
    'jp': ['초밥', '라멘'],
    'FR': ['카망베르', '바게트'],
  };

  /// rootBundle.loadString 모킹 헬퍼.
  void setUpMockAsset({
    required String assetPath,
    required String jsonString,
  }) {
    ServicesBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
      final requestedPath = utf8.decode(message!.buffer.asUint8List());
      if (requestedPath == assetPath) {
        return ByteData.view(
          Uint8List.fromList(utf8.encode(jsonString)).buffer,
        );
      }
      return null;
    });
  }

  void tearDownMockAsset() {
    ServicesBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  }

  group('WorldLocalSpecialtyRepositoryImpl', () {
    setUp(() {
      // Repository의 static 캐시 초기화
      WorldLocalSpecialtyRepositoryImpl.resetCache();
      // rootBundle의 내부 문자열 캐시 초기화
      rootBundle.evict(defaultPath);
    });

    tearDown(() {
      tearDownMockAsset();
    });

    test('JSON 파싱 성공 - 존재하는 국가 코드로 특산품 리스트를 반환한다', () async {
      // arrange
      setUpMockAsset(
        assetPath: defaultPath,
        jsonString: jsonEncode(testJsonData),
      );
      const repository = WorldLocalSpecialtyRepositoryImpl();

      // act
      final result = await repository.fetchForCountry('kr');

      // assert
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(['김치', '불고기', '비빔밥']));
    });

    test('미존재 국가 코드 조회 시 빈 리스트를 반환한다', () async {
      // arrange
      setUpMockAsset(
        assetPath: defaultPath,
        jsonString: jsonEncode(testJsonData),
      );
      const repository = WorldLocalSpecialtyRepositoryImpl();

      // act
      final result = await repository.fetchForCountry('zz');

      // assert
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isEmpty);
    });

    test('국가 코드를 대소문자 구분 없이 조회한다 (입력 대문자)', () async {
      // arrange
      setUpMockAsset(
        assetPath: defaultPath,
        jsonString: jsonEncode(testJsonData),
      );
      const repository = WorldLocalSpecialtyRepositoryImpl();

      // act - JSON 키 'kr'에 대해 대문자 'KR'로 조회
      final result = await repository.fetchForCountry('KR');

      // assert
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(['김치', '불고기', '비빔밥']));
    });

    test('JSON 키가 대문자여도 소문자로 정규화하여 조회된다', () async {
      // arrange - JSON에 'FR' (대문자) 키 존재
      setUpMockAsset(
        assetPath: defaultPath,
        jsonString: jsonEncode(testJsonData),
      );
      const repository = WorldLocalSpecialtyRepositoryImpl();

      // act - 소문자 'fr'로 조회
      final result = await repository.fetchForCountry('fr');

      // assert - _loadSpecialties에서 key.toLowerCase() 적용
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(['카망베르', '바게트']));
    });

    test('에셋 로드 실패 시 ParsingFailure를 반환한다', () async {
      // arrange - null 반환으로 에셋 없음을 시뮬레이션
      ServicesBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (ByteData? message) async {
        return null;
      });
      const repository = WorldLocalSpecialtyRepositoryImpl();

      // act
      final result = await repository.fetchForCountry('kr');

      // assert
      expect(result.isError, isTrue);
      expect(result.failureOrNull, isA<ParsingFailure>());
      expect(
        result.failureOrNull?.message,
        equals('특산품 정보를 불러오지 못했습니다.'),
      );
    });

    test('캐싱: 두 번째 호출에서는 에셋을 다시 로드하지 않는다', () async {
      // arrange
      int loadCount = 0;
      ServicesBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (ByteData? message) async {
        final requestedPath = utf8.decode(message!.buffer.asUint8List());
        if (requestedPath == defaultPath) {
          loadCount++;
          return ByteData.view(
            Uint8List.fromList(
              utf8.encode(jsonEncode(testJsonData)),
            ).buffer,
          );
        }
        return null;
      });
      const repository = WorldLocalSpecialtyRepositoryImpl();

      // act - 첫 번째 호출 (캐시 미스 -> 에셋 로드)
      final result1 = await repository.fetchForCountry('kr');
      // act - 두 번째 호출 (캐시 히트 -> 에셋 로드 없음)
      final result2 = await repository.fetchForCountry('jp');

      // assert
      expect(result1.isSuccess, isTrue);
      expect(result1.dataOrNull, equals(['김치', '불고기', '비빔밥']));
      expect(result2.isSuccess, isTrue);
      expect(result2.dataOrNull, equals(['초밥', '라멘']));
      // 에셋 파일은 1회만 로드되어야 한다
      expect(loadCount, equals(1));
    });
  });
}
