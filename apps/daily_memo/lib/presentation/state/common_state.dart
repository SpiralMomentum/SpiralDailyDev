import 'package:freezed_annotation/freezed_annotation.dart';

part 'common_state.freezed.dart';

@freezed
class CommonState<T> with _$CommonState<T> {
  const CommonState._();

  const factory CommonState.init(final T data) = _init<T>;
  const factory CommonState.loading() = _loading;
  const factory CommonState.success(final T data) = _success<T>;
  const factory CommonState.error(final Exception exception) = _error;

  bool get isInit => maybeWhen(init: (_) => true, orElse: () => false);

  bool get isLoading =>  maybeWhen(loading: () => true, orElse: () => false);

  bool get isSuccess => maybeMap(success: (_) => true, orElse: () => false);

  bool get isError => maybeWhen(error: (_) => true, orElse: () => false);

  T? get data => maybeWhen(success: (data) => data, orElse: () => null);
}