import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utils/result/result.dart';

import '../../domain/repositories/search_repository.dart';
import '../../domain/usecases/search_articles.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit({
    required SearchArticles searchArticles,
    required SearchRepository repository,
  })  : _searchArticles = searchArticles,
        _repository = repository,
        super(const SearchState());

  final SearchArticles _searchArticles;
  final SearchRepository _repository;

  Timer? _debounceTimer;
  String? _lastQuery;
  Completer<void>? _activeSearch;

  void search(String query) {
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      emit(state.copyWith(
        status: SearchStatus.initial,
        articles: [],
        query: '',
        hasMore: false,
        cursor: () => null,
        errorMessage: () => null,
      ));
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _executeSearch(query);
    });
  }

  Future<void> _executeSearch(String query) async {
    // Dedup: skip if same query is already in progress
    if (_lastQuery == query && _activeSearch != null && !_activeSearch!.isCompleted) {
      return;
    }

    _lastQuery = query;
    _activeSearch = Completer<void>();

    emit(state.copyWith(
      status: SearchStatus.loading,
      query: query,
      cursor: () => null,
    ));

    final result = await _searchArticles(query: query);

    // Ensure we only emit if this is still the latest query
    if (_lastQuery != query) {
      _activeSearch?.complete();
      return;
    }

    switch (result) {
      case Success(data: final paginated):
        emit(state.copyWith(
          status: SearchStatus.loaded,
          articles: paginated.articles,
          hasMore: paginated.hasMore,
          cursor: () => paginated.nextCursor,
          errorMessage: () => null,
        ));
      case ErrorResult(failure: final failure):
        emit(state.copyWith(
          status: SearchStatus.error,
          errorMessage: () => failure.message,
        ));
    }

    _activeSearch?.complete();
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.status == SearchStatus.loading) return;

    final result = await _searchArticles(
      query: state.query,
      cursor: state.cursor,
    );

    switch (result) {
      case Success(data: final paginated):
        emit(state.copyWith(
          articles: [...state.articles, ...paginated.articles],
          hasMore: paginated.hasMore,
          cursor: () => paginated.nextCursor,
        ));
      case ErrorResult(failure: final failure):
        emit(state.copyWith(
          status: SearchStatus.error,
          errorMessage: () => failure.message,
        ));
    }
  }

  Future<void> loadHistory() async {
    final result = await _repository.getSearchHistory();

    switch (result) {
      case Success(data: final history):
        emit(state.copyWith(searchHistory: history));
      case ErrorResult():
        break;
    }
  }

  Future<void> clearHistory() async {
    final result = await _repository.clearSearchHistory();

    switch (result) {
      case Success():
        emit(state.copyWith(searchHistory: []));
      case ErrorResult():
        break;
    }
  }

  Future<void> saveQuery(String query) async {
    if (query.isEmpty) return;
    await _repository.saveSearchQuery(query);
    await loadHistory();
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
