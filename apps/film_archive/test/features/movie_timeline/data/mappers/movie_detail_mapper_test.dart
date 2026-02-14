import 'package:film_archive/features/movie_timeline/data/mappers/movie_detail_mapper.dart';
import 'package:film_archive/features/movie_timeline/data/models/movie_detail_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MovieDetailMapper', () {
    test('toDomain은 DTO의 모든 필드를 Entity에 정확히 매핑한다', () {
      final dto = MovieDetailDto(
        id: 550,
        title: 'Fight Club',
        releaseYear: 1999,
        countries: ['United States of America'],
        genres: ['Drama'],
        runtimeMinutes: 139,
        rating: 8.4,
        overview: 'An insomniac office worker.',
      );

      final entity = MovieDetailMapper.toDomain(dto);

      expect(entity.id, 550);
      expect(entity.title, 'Fight Club');
      expect(entity.releaseYear, 1999);
      expect(entity.countries, ['United States of America']);
      expect(entity.genres, ['Drama']);
      expect(entity.runtimeMinutes, 139);
      expect(entity.rating, 8.4);
      expect(entity.overview, 'An insomniac office worker.');
    });

    test('toDomain은 null 가능 필드가 null인 경우 그대로 전달한다', () {
      final dto = MovieDetailDto(
        id: 1,
        title: 'Unknown Movie',
        releaseYear: null,
        countries: [],
        genres: [],
        runtimeMinutes: null,
        rating: null,
        overview: '',
      );

      final entity = MovieDetailMapper.toDomain(dto);

      expect(entity.releaseYear, isNull);
      expect(entity.runtimeMinutes, isNull);
      expect(entity.rating, isNull);
      expect(entity.countries, isEmpty);
      expect(entity.genres, isEmpty);
      expect(entity.overview, '');
    });

    test('toDomain은 다수의 국가와 장르를 정상 매핑한다', () {
      final dto = MovieDetailDto(
        id: 278,
        title: 'The Shawshank Redemption',
        releaseYear: 1994,
        countries: ['United States of America', 'United Kingdom'],
        genres: ['Drama', 'Crime'],
        runtimeMinutes: 142,
        rating: 8.7,
        overview: 'Imprisoned in the 1940s.',
      );

      final entity = MovieDetailMapper.toDomain(dto);

      expect(entity.countries, hasLength(2));
      expect(entity.countries, contains('United Kingdom'));
      expect(entity.genres, hasLength(2));
      expect(entity.genres, contains('Crime'));
    });
  });
}
