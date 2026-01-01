import 'network_exception.dart';

sealed class NetworkResult<T> {
  const NetworkResult();

  bool get isSuccess => this is NetworkSuccess<T>;
  bool get isError => this is NetworkError<T>;

  T? get dataOrNull =>
      this is NetworkSuccess<T> ? (this as NetworkSuccess<T>).data : null;
  NetworkException? get errorOrNull =>
      this is NetworkError<T> ? (this as NetworkError<T>).error : null;

  R when<R>({
    required R Function(T data) success,
    required R Function(NetworkException error) error,
  }) {
    final current = this;
    if (current is NetworkSuccess<T>) {
      return success(current.data);
    }
    return error((current as NetworkError<T>).error);
  }

  NetworkResult<R> map<R>(R Function(T data) transform) {
    final current = this;
    if (current is NetworkSuccess<T>) {
      return NetworkSuccess<R>(transform(current.data));
    }
    return NetworkError<R>((current as NetworkError<T>).error);
  }

  NetworkResult<R> flatMap<R>(NetworkResult<R> Function(T data) transform) {
    final current = this;
    if (current is NetworkSuccess<T>) {
      return transform(current.data);
    }
    return NetworkError<R>((current as NetworkError<T>).error);
  }
}

class NetworkSuccess<T> extends NetworkResult<T> {
  const NetworkSuccess(this.data);

  final T data;
}

class NetworkError<T> extends NetworkResult<T> {
  const NetworkError(this.error);

  final NetworkException error;
}
