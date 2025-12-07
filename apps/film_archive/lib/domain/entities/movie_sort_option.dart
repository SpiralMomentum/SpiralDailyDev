enum MovieSortOption {
  popularity('popularity.desc', 'TMDB 인기 지표순'),
  voteCount('vote_count.desc', 'TMDB 투표 수 많은 순'),
  revenue('revenue.desc', 'TMDB 매출순');

  const MovieSortOption(this.sortQuery, this.displayLabel);

  final String sortQuery;
  final String displayLabel;
}
