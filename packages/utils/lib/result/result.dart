import 'failure.dart';

sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isError => this is ErrorResult<T>;

  T? get dataOrNull => this is Success<T> ? (this as Success<T>).data : null;
  Failure? get failureOrNull =>
      this is ErrorResult<T> ? (this as ErrorResult<T>).failure : null;

  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) error,
  }) {
    final current = this;
    if (current is Success<T>) {
      return success(current.data);
    }
    return error((current as ErrorResult<T>).failure);
  }

  Result<R> map<R>(R Function(T value) transform) {
    final current = this;
    if (current is Success<T>) {
      return Success<R>(transform(current.data));
    }
    return ErrorResult<R>((current as ErrorResult<T>).failure);
  }

  Result<R> flatMap<R>(Result<R> Function(T value) transform) {
    final current = this;
    if (current is Success<T>) {
      return transform(current.data);
    }
    return ErrorResult<R>((current as ErrorResult<T>).failure);
  }

  Result<T> mapError(Failure Function(Failure failure) transform) {
    final current = this;
    if (current is ErrorResult<T>) {
      return ErrorResult<T>(transform(current.failure));
    }
    return Success<T>((current as Success<T>).data);
  }

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onError,
  }) {
    return when(success: onSuccess, error: onError);
  }
}

class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;
}

class ErrorResult<T> extends Result<T> {
  const ErrorResult(this.failure);

  final Failure failure;
}

Result<T> guard<T>({
  required T Function() action,
  required Failure Function(Object error, StackTrace stackTrace) onError,
}) {
  try {
    return Success<T>(action());
  } catch (error, stackTrace) {
    return ErrorResult<T>(onError(error, stackTrace));
  }
}

Future<Result<T>> guardAsync<T>({
  required Future<T> Function() action,
  required Failure Function(Object error, StackTrace stackTrace) onError,
}) async {
  try {
    return Success<T>(await action());
  } catch (error, stackTrace) {
    return ErrorResult<T>(onError(error, stackTrace));
  }
}
