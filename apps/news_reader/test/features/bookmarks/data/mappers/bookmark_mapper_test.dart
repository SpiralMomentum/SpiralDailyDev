import 'package:flutter_test/flutter_test.dart';
import 'package:apps.news_reader/features/bookmarks/data/mappers/bookmark_mapper.dart';
import 'package:apps.news_reader/features/bookmarks/domain/entities/bookmark.dart';

void main() {
  group('BookmarkMapper', () {
    group('toDomain', () {
      test('maps row to Bookmark correctly', () {
        final row = {
          'article_id': 'art-1',
          'title': 'Test Title',
          'summary': 'Summary text',
          'content': 'Full content',
          'image_url': 'https://img.com/1.jpg',
          'category': 'technology',
          'saved_at': 1704067200000,
          'sync_status': 'pendingUpload',
          'highlighted_text': 'important part',
        };

        final bookmark = BookmarkMapper.toDomain(row);

        expect(bookmark.articleId, 'art-1');
        expect(bookmark.title, 'Test Title');
        expect(bookmark.summary, 'Summary text');
        expect(bookmark.content, 'Full content');
        expect(bookmark.imageUrl, 'https://img.com/1.jpg');
        expect(bookmark.category, 'technology');
        expect(bookmark.syncStatus, SyncStatus.pendingUpload);
        expect(bookmark.highlightedText, 'important part');
      });

      test('handles null optional fields with defaults', () {
        final row = {
          'article_id': 'art-1',
          'title': 'Title',
          'saved_at': 1704067200000,
        };

        final bookmark = BookmarkMapper.toDomain(row);

        expect(bookmark.summary, '');
        expect(bookmark.content, '');
        expect(bookmark.imageUrl, '');
        expect(bookmark.category, 'general');
        expect(bookmark.syncStatus, SyncStatus.synced);
        expect(bookmark.highlightedText, isNull);
      });
    });

    group('toMap', () {
      test('maps Bookmark to Map correctly', () {
        final bookmark = Bookmark(
          articleId: 'art-1',
          title: 'Title',
          summary: 'Summary',
          content: 'Content',
          imageUrl: 'url',
          category: 'technology',
          savedAt: DateTime.fromMillisecondsSinceEpoch(1704067200000),
          syncStatus: SyncStatus.pendingUpload,
        );

        final map = BookmarkMapper.toMap(bookmark);

        expect(map['article_id'], 'art-1');
        expect(map['title'], 'Title');
        expect(map['summary'], 'Summary');
        expect(map['content'], 'Content');
        expect(map['image_url'], 'url');
        expect(map['category'], 'technology');
        expect(map['saved_at'], 1704067200000);
        expect(map['sync_status'], 'pendingUpload');
        expect(map['version'], 1);
      });
    });
  });
}
