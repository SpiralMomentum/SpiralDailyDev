import 'package:apps.news_reader/app/di/service_locator.dart';
import 'package:apps.news_reader/app/route/app_router.dart';
import 'package:apps.news_reader/app/route/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() async {
    await ServiceLocator.setupLocatorSingleton();
  });

  tearDown(() {
    getIt.reset();
  });

  group('AppRouter', () {
    test('creates router with default initial location /feed', () {
      final router = createRouter();
      expect(router.routerDelegate, isNotNull);
    });

    test('creates router with onboarding initial location', () {
      final router = createRouter(
        initialLocation: AppRoutes.onboarding.path,
      );
      expect(router.routerDelegate, isNotNull);
    });

    test('all route paths are defined', () {
      expect(AppRoutes.values.length, 7);
      expect(AppRoutes.feed.path, '/feed');
      expect(AppRoutes.onboarding.path, '/onboarding');
      expect(AppRoutes.articleDetail.path, '/article/:id');
      expect(AppRoutes.comments.path, '/article/:id/comments');
      expect(AppRoutes.bookmarks.path, '/bookmarks');
      expect(AppRoutes.search.path, '/search');
      expect(AppRoutes.settings.path, '/settings');
    });
  });
}
