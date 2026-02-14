import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_trade_show/features/info_shelf/models/model/show_data.dart';

void main() {
  group('ShowData', () {
    final validJson = {
      'DP_NAME': 'Modern Art Exhibition',
      'DP_MAIN_IMG': 'https://example.com/img.png',
      'DP_PLACE': 'Seoul Museum of Art',
      'DP_INFO': '<p>A great <b>exhibition</b> of modern art.</p>',
      'DP_START': '2024-03-01T00:00:00.000',
      'DP_END': '2024-06-30T00:00:00.000',
    };

    test('fromJson으로 올바르게 파싱된다', () {
      final showData = ShowData.fromJson(validJson);

      expect(showData.title, 'Modern Art Exhibition');
      expect(showData.thumbnail, 'https://example.com/img.png');
      expect(showData.place, 'Seoul Museum of Art');
      expect(showData.description, '<p>A great <b>exhibition</b> of modern art.</p>');
      expect(showData.startTime, DateTime(2024, 3, 1));
      expect(showData.endTime, DateTime(2024, 6, 30));
    });

    test('toJson으로 올바르게 직렬화된다', () {
      final showData = ShowData.fromJson(validJson);
      final json = showData.toJson();

      expect(json['DP_NAME'], 'Modern Art Exhibition');
      expect(json['DP_MAIN_IMG'], 'https://example.com/img.png');
      expect(json['DP_PLACE'], 'Seoul Museum of Art');
      expect(json['DP_INFO'], '<p>A great <b>exhibition</b> of modern art.</p>');
      expect(json['DP_START'], isNotNull);
      expect(json['DP_END'], isNotNull);
    });

    test('toDomainEntity()가 HTML 태그를 제거한 Info 객체를 반환한다', () {
      final showData = ShowData.fromJson(validJson);
      final info = showData.toDomainEntity();

      expect(info.title, 'Modern Art Exhibition');
      expect(info.thumbnail, 'https://example.com/img.png');
      expect(info.place, 'Seoul Museum of Art');
      // HTML 태그가 제거된 순수 텍스트
      expect(info.description, 'A great exhibition of modern art.');
      expect(info.startTime, DateTime(2024, 3, 1));
      expect(info.endTime, DateTime(2024, 6, 30));
    });

    test('toDomainEntity()가 HTML이 없는 description도 정상 처리한다', () {
      final plainJson = {
        'DP_NAME': 'Simple Show',
        'DP_MAIN_IMG': 'https://example.com/simple.png',
        'DP_PLACE': 'Busan',
        'DP_INFO': 'plain text description',
        'DP_START': '2024-01-01T00:00:00.000',
        'DP_END': '2024-12-31T00:00:00.000',
      };
      final showData = ShowData.fromJson(plainJson);
      final info = showData.toDomainEntity();

      expect(info.description, 'plain text description');
    });

    test('fromJson -> toJson -> fromJson 라운드트립이 데이터를 유지한다', () {
      final original = ShowData.fromJson(validJson);
      final json = original.toJson();
      final restored = ShowData.fromJson(json);

      expect(restored.title, original.title);
      expect(restored.thumbnail, original.thumbnail);
      expect(restored.place, original.place);
      expect(restored.description, original.description);
    });
  });
}
