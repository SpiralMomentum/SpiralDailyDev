abstract class PushNotificationService {
  Future<void> initialize();
  Future<String?> getToken();
  Future<void> subscribeToTopic(String topic);
  Future<void> unsubscribeFromTopic(String topic);
  Stream<Map<String, dynamic>> get onMessage;
}

class MockPushNotificationService implements PushNotificationService {
  final Set<String> _subscribedTopics = {};

  Set<String> get subscribedTopics => Set.unmodifiable(_subscribedTopics);

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> getToken() async => 'mock-fcm-token';

  @override
  Future<void> subscribeToTopic(String topic) async {
    _subscribedTopics.add(topic);
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    _subscribedTopics.remove(topic);
  }

  @override
  Stream<Map<String, dynamic>> get onMessage => const Stream.empty();
}
