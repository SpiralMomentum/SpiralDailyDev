import 'package:film_archive/features/movie_timeline/data/mappers/movie_summary_mapper.dart';
import 'package:film_archive/features/movie_timeline/data/models/movie_summary_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MovieSummaryMapper', () {
    test('toDomain은 DTO의 모든 필드를 Entity에 정확히 매핑한다', () {
      final dto = MovieSummaryDto(
        id: 550,
        year: 1999,
        title: 'Fight Club',
        overview: 'An insomniac office worker and a devil-may-care soap maker.',
      );

      final entity = MovieSummaryMapper.toDomain(dto);

      expect(entity.id, 550);
      expect(entity.year, 1999);
      expect(entity.title, 'Fight Club');
      expect(entity.overview,
          'An insomniac office worker and a devil-may-care soap maker.');
    });

    test('toDomain은 빈 overview를 그대로 전달한다', () {
      final dto = MovieSummaryDto(
        id: 1,
        year: 2020,
        title: 'Test Movie',
        overview: '',
      );

      final entity = MovieSummaryMapper.toDomain(dto);

      expect(entity.overview, '');
      // Entity의 displayOverview에서 빈 값 처리가 이루어진다
      expect(entity.displayOverview, '소개 준비 중입니다.');
    });

    test('toDomain은 한글 제목과 개요를 정상 변환한다', () {
      final dto = MovieSummaryDto(
        id: 999,
        year: 2023,
        title: '서울의 봄',
        overview: '1979년 12월 12일, 대한민국의 운명을 바꾼 하루.',
      );

      final entity = MovieSummaryMapper.toDomain(dto);

      expect(entity.id, 999);
      expect(entity.year, 2023);
      expect(entity.title, '서울의 봄');
      expect(entity.overview, '1979년 12월 12일, 대한민국의 운명을 바꾼 하루.');
    });

    test('toDomain은 id가 0인 경우에도 정상 매핑한다', () {
      final dto = MovieSummaryDto(
        id: 0,
        year: 2000,
        title: 'Zero ID Movie',
        overview: 'A movie with zero id.',
      );

      final entity = MovieSummaryMapper.toDomain(dto);

      expect(entity.id, 0);
      expect(entity.year, 2000);
    });
  });
}
