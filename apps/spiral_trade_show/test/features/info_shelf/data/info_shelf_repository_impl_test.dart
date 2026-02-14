import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spiral_trade_show/features/info_shelf/data/datasources/info_shelf_remote_data_source.dart';
import 'package:spiral_trade_show/features/info_shelf/data/exceptions/external_exception.dart';
import 'package:spiral_trade_show/features/info_shelf/data/info_shelf_repository_impl.dart';
import 'package:spiral_trade_show/features/info_shelf/models/model/my_response.dart';
import 'package:spiral_trade_show/features/info_shelf/models/model/show_data.dart';
import 'package:spiral_trade_show/features/info_shelf/models/model/trade_show_info.dart';
import 'package:spiral_trade_show/features/info_shelf/models/model/trades.dart';
import 'package:ui_components/card/info.dart';
import 'package:utils/utils.dart';

class MockInfoShelfRemoteDataSource extends Mock
    implements InfoShelfRemoteDataSource {}

void main() {
  late MockInfoShelfRemoteDataSource mockDataSource;
  late InfoShelfRepositoryImpl repository;

  final testShowData = ShowData(
    'test title',
    'https://example.com/img.png',
    'Seoul',
    '<p>test description</p>',
    DateTime(2024, 1, 1),
    DateTime(2024, 1, 31),
  );

  final testTrades = Trades(
    TradeShowInfo(
      1,
      MyResponse('INFO-000', 'success'),
      [testShowData],
    ),
  );

  setUp(() {
    mockDataSource = MockInfoShelfRemoteDataSource();
    repository = InfoShelfRepositoryImpl(mockDataSource);
  });

  group('InfoShelfRepositoryImpl', () {
    test('dataSource 호출 성공 시 ShowData를 Info 도메인 엔티티로 변환하여 반환한다', () async {
      when(() => mockDataSource.fetchInfo(startIndex: 0, endIndex: 30))
          .thenAnswer((_) async => Success(testTrades));

      final result = await repository.fetchInfo(0, 30);

      expect(result.isSuccess, isTrue);
      final infoList = (result as Success<List<Info>>).data;
      expect(infoList.length, 1);
      expect(infoList[0].title, 'test title');
      expect(infoList[0].description, 'test description');
    });

    test('dataSource가 NetworkExternalException 반환 시 NetworkFailure로 매핑한다',
        () async {
      const exception = NetworkExternalException(
        NetworkExternalExceptionType.timeout,
        message: 'connection timeout',
      );
      when(() => mockDataSource.fetchInfo(startIndex: 0, endIndex: 30))
          .thenAnswer((_) async => const ErrorResult(exception));

      final result = await repository.fetchInfo(0, 30);

      expect(result.isError, isTrue);
      final failure = (result as ErrorResult<List<Info>>).failure;
      expect(failure, isA<NetworkFailure>());
      expect(failure.message, 'connection timeout');
    });

    test('dataSource가 일반 ExternalException 반환 시에도 NetworkFailure로 매핑한다',
        () async {
      const exception = ExternalException(message: 'unknown error');
      when(() => mockDataSource.fetchInfo(startIndex: 0, endIndex: 30))
          .thenAnswer((_) async => const ErrorResult(exception));

      final result = await repository.fetchInfo(0, 30);

      expect(result.isError, isTrue);
      final failure = (result as ErrorResult<List<Info>>).failure;
      expect(failure, isA<NetworkFailure>());
      expect(failure.message, '전시 정보를 불러오지 못했습니다.');
    });

    test('dataSource에 startIndex, endIndex가 정확히 전달된다', () async {
      when(() => mockDataSource.fetchInfo(startIndex: 10, endIndex: 20))
          .thenAnswer((_) async => Success(testTrades));

      await repository.fetchInfo(10, 20);

      verify(() => mockDataSource.fetchInfo(startIndex: 10, endIndex: 20))
          .called(1);
    });
  });
}
