import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_trade_show/features/info_shelf/models/model/trades.dart';

void main() {
  group('Trades', () {
    final validJson = {
      'ListExhibitionOfSeoulMOAInfo': {
        'list_total_count': 2,
        'RESULT': {
          'CODE': 'INFO-000',
          'MESSAGE': 'success',
        },
        'row': [
          {
            'DP_NAME': 'Exhibition A',
            'DP_MAIN_IMG': 'https://example.com/a.png',
            'DP_PLACE': 'Gallery A',
            'DP_INFO': 'description A',
            'DP_START': '2024-01-01T00:00:00.000',
            'DP_END': '2024-01-31T00:00:00.000',
          },
          {
            'DP_NAME': 'Exhibition B',
            'DP_MAIN_IMG': 'https://example.com/b.png',
            'DP_PLACE': 'Gallery B',
            'DP_INFO': 'description B',
            'DP_START': '2024-02-01T00:00:00.000',
            'DP_END': '2024-02-28T00:00:00.000',
          },
        ],
      },
    };

    test('fromJson으로 올바르게 파싱된다', () {
      final trades = Trades.fromJson(validJson);

      expect(trades.tradeShowInfo.totalCount, 2);
      expect(trades.tradeShowInfo.myResponse.responseCode, 'INFO-000');
      expect(trades.tradeShowInfo.myResponse.message, 'success');
      expect(trades.tradeShowInfo.showDataList.length, 2);
      expect(trades.tradeShowInfo.showDataList[0].title, 'Exhibition A');
      expect(trades.tradeShowInfo.showDataList[1].title, 'Exhibition B');
    });

    test('toJson으로 올바르게 직렬화된다', () {
      final trades = Trades.fromJson(validJson);
      final json = trades.toJson();

      expect(json.containsKey('ListExhibitionOfSeoulMOAInfo'), isTrue);
      final inner = json['ListExhibitionOfSeoulMOAInfo'] as Map<String, dynamic>;
      expect(inner['list_total_count'], 2);
      expect(inner['RESULT']['CODE'], 'INFO-000');
      expect((inner['row'] as List).length, 2);
    });

    test('fromJson -> toJson -> fromJson 라운드트립이 동일한 데이터를 유지한다', () {
      final original = Trades.fromJson(validJson);
      final json = original.toJson();
      final restored = Trades.fromJson(json);

      expect(restored.tradeShowInfo.totalCount, original.tradeShowInfo.totalCount);
      expect(
        restored.tradeShowInfo.myResponse.responseCode,
        original.tradeShowInfo.myResponse.responseCode,
      );
      expect(
        restored.tradeShowInfo.showDataList.length,
        original.tradeShowInfo.showDataList.length,
      );
      expect(
        restored.tradeShowInfo.showDataList[0].title,
        original.tradeShowInfo.showDataList[0].title,
      );
    });
  });
}
