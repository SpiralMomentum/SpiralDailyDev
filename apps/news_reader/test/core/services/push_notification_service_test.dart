import 'package:flutter_test/flutter_test.dart';
import 'package:apps.news_reader/core/services/push_notification_service.dart';

void main() {
  group('MockPushNotificationService', () {
    late MockPushNotificationService service;

    setUp(() {
      service = MockPushNotificationService();
    });

    test('initializes without error', () async {
      await expectLater(service.initialize(), completes);
    });

    test('returns mock token', () async {
      expect(await service.getToken(), 'mock-fcm-token');
    });

    test('subscribes and unsubscribes from topics', () async {
      await service.subscribeToTopic('technology');
      await service.subscribeToTopic('science');
      expect(service.subscribedTopics, {'technology', 'science'});

      await service.unsubscribeFromTopic('technology');
      expect(service.subscribedTopics, {'science'});
    });

    test('onMessage returns empty stream', () async {
      final messages = await service.onMessage.toList();
      expect(messages, isEmpty);
    });
  });
}
