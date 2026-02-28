import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/result/result.dart';
import 'package:utils/result/failure.dart';
import 'package:apps.news_reader/features/bookmarks/domain/repositories/bookmark_repository.dart';
import 'package:apps.news_reader/features/bookmarks/domain/usecases/sync_bookmarks.dart';

class MockBookmarkRepository extends Mock implements BookmarkRepository {}

void main() {
  late SyncBookmarks usecase;
  late MockBookmarkRepository repository;

  setUp(() {
    repository = MockBookmarkRepository();
    usecase = SyncBookmarks(repository);
  });

  group('SyncBookmarks', () {
    test('delegates to repository.syncBookmarks and returns synced count',
        () async {
      when(() => repository.syncBookmarks())
          .thenAnswer((_) async => const Success(3));

      final result = await usecase();

      expect(result, isA<Success<int>>());
      final success = result as Success<int>;
      expect(success.data, 3);
      verify(() => repository.syncBookmarks()).called(1);
    });

    test('returns ErrorResult when repository fails', () async {
      when(() => repository.syncBookmarks()).thenAnswer(
        (_) async =>
            ErrorResult(const LocalStorageFailure(message: 'sync failed')),
      );

      final result = await usecase();

      expect(result, isA<ErrorResult<int>>());
    });
  });
}
