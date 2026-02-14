import 'package:networking/networking.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spiral_trade_show/features/info_shelf/data/exceptions/external_exception.dart';
import 'package:spiral_trade_show/features/info_shelf/external/remote/info_shelf_remote_data_source_impl.dart';
import 'package:spiral_trade_show/features/info_shelf/models/model/trades.dart';
import 'package:utils/utils.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late InfoShelfRemoteDataSourceImpl dataSource;

  const baseUrl = 'http://openapi.seoul.go.kr:8088';
  const serviceKey = 'testKey';
  const format = 'json';
  const serviceName = 'ListExhibitionOfSeoulMOAInfo';

  final validResponseData = {
    'ListExhibitionOfSeoulMOAInfo': {
      'list_total_count': 1,
      'RESULT': {
        'CODE': 'INFO-000',
        'MESSAGE': 'success',
      },
      'row': [
        {
          'DP_NAME': 'test title',
          'DP_MAIN_IMG': 'https://example.com/img.png',
          'DP_PLACE': 'Seoul',
          'DP_INFO': 'test description',
          'DP_START': '2024-01-01T00:00:00.000',
          'DP_END': '2024-01-31T00:00:00.000',
        },
      ],
    },
  };

  setUp(() {
    mockDio = MockDio();
    dataSource = InfoShelfRemoteDataSourceImpl(
      dio: mockDio,
      baseUrl: baseUrl,
      serviceKey: serviceKey,
      format: format,
      serviceName: serviceName,
    );
  });

  setUpAll(() {
    registerFallbackValue(Options());
  });

  group('InfoShelfRemoteDataSourceImpl', () {
    test('성공 응답 시 Trades 객체로 파싱하여 Success를 반환한다', () async {
      when(() => mockDio.get(
            any(),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: validResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(),
          ));

      final result = await dataSource.fetchInfo(startIndex: 0, endIndex: 30);

      expect(result.isSuccess, isTrue);
      final trades = (result as Success<Trades>).data;
      expect(trades.tradeShowInfo.totalCount, 1);
      expect(trades.tradeShowInfo.showDataList.first.title, 'test title');
    });

    test('올바른 URL로 Dio를 호출한다', () async {
      when(() => mockDio.get(
            any(),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: validResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(),
          ));

      await dataSource.fetchInfo(startIndex: 0, endIndex: 30);

      verify(() => mockDio.get(
            '$baseUrl/$serviceKey/$format/$serviceName/0/30/',
            options: any(named: 'options'),
          )).called(1);
    });

    test('DioException connectionTimeout 시 NetworkExternalException timeout을 반환한다',
        () async {
      when(() => mockDio.get(
            any(),
            options: any(named: 'options'),
          )).thenThrow(DioException(
            type: DioExceptionType.connectionTimeout,
            requestOptions: RequestOptions(),
            message: 'Connection timed out',
          ));

      final result = await dataSource.fetchInfo(startIndex: 0, endIndex: 30);

      expect(result.isError, isTrue);
      final failure = (result as ErrorResult<Trades>).failure;
      expect(failure, isA<NetworkExternalException>());
      final networkException = failure as NetworkExternalException;
      expect(networkException.type, NetworkExternalExceptionType.timeout);
    });

    test('DioException connectionError 시 NetworkExternalException noConnection을 반환한다',
        () async {
      when(() => mockDio.get(
            any(),
            options: any(named: 'options'),
          )).thenThrow(DioException(
            type: DioExceptionType.connectionError,
            requestOptions: RequestOptions(),
            message: 'No connection',
          ));

      final result = await dataSource.fetchInfo(startIndex: 0, endIndex: 30);

      expect(result.isError, isTrue);
      final failure = (result as ErrorResult<Trades>).failure;
      final networkException = failure as NetworkExternalException;
      expect(networkException.type, NetworkExternalExceptionType.noConnection);
    });

    test('DioException badResponse 시 NetworkExternalException server를 반환한다',
        () async {
      when(() => mockDio.get(
            any(),
            options: any(named: 'options'),
          )).thenThrow(DioException(
            type: DioExceptionType.badResponse,
            requestOptions: RequestOptions(),
            message: 'Bad response',
          ));

      final result = await dataSource.fetchInfo(startIndex: 0, endIndex: 30);

      expect(result.isError, isTrue);
      final failure = (result as ErrorResult<Trades>).failure;
      final networkException = failure as NetworkExternalException;
      expect(networkException.type, NetworkExternalExceptionType.unknown);
    });

    test('일반 Exception 발생 시 NetworkExternalException unknown을 반환한다', () async {
      when(() => mockDio.get(
            any(),
            options: any(named: 'options'),
          )).thenThrow(Exception('unexpected error'));

      final result = await dataSource.fetchInfo(startIndex: 0, endIndex: 30);

      expect(result.isError, isTrue);
      final failure = (result as ErrorResult<Trades>).failure;
      final networkException = failure as NetworkExternalException;
      expect(networkException.type, NetworkExternalExceptionType.unknown);
    });
  });
}
