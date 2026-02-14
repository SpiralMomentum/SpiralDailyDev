import 'package:dio/dio.dart';

import '../core/network_failure.dart';

NetworkFailure mapDioError(DioException exception) {
  switch (exception.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const NetworkFailure(
        type: NetworkFailureType.timeout,
        message: '요청 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.',
      );
    // TODO(보안): badCertificate는 SSL/TLS 인증서 검증 실패를 의미하므로
    //  badResponse와 분리하여 별도 처리해야 한다. MITM 공격 가능성을 사용자에게 알리거나
    //  요청을 차단하는 전용 NetworkFailureType 추가를 검토할 것.
    case DioExceptionType.badCertificate:
    case DioExceptionType.badResponse:
      return NetworkFailure(
        type: _failureFromStatus(exception.response?.statusCode),
        statusCode: exception.response?.statusCode,
        message: _messageFromStatus(exception.response?.statusCode),
        rawBody: exception.response?.data?.toString(),
      );
    case DioExceptionType.connectionError:
      return const NetworkFailure(
        type: NetworkFailureType.noConnection,
        message: '네트워크 연결을 확인한 뒤 다시 시도해주세요.',
      );
    case DioExceptionType.cancel:
      return const NetworkFailure(
        type: NetworkFailureType.cancelled,
        message: '요청이 취소되었습니다.',
      );
    case DioExceptionType.unknown:
      return NetworkFailure(
        type: NetworkFailureType.unknown,
        message: exception.message ?? '알 수 없는 오류가 발생했습니다.',
      );
  }
}

NetworkFailureType _failureFromStatus(int? statusCode) {
  if (statusCode == null) {
    return NetworkFailureType.unknown;
  }
  if (statusCode == 401) return NetworkFailureType.unauthorized;
  if (statusCode == 403) return NetworkFailureType.forbidden;
  if (statusCode == 404) return NetworkFailureType.notFound;
  if (statusCode >= 500) return NetworkFailureType.server;
  return NetworkFailureType.client;
}

String _messageFromStatus(int? statusCode) {
  if (statusCode == 401) {
    return '인증 정보가 유효하지 않습니다.';
  }
  if (statusCode == 403) {
    return '요청에 대한 권한이 없습니다.';
  }
  if (statusCode == 404) {
    return '요청한 리소스를 찾을 수 없습니다.';
  }
  if (statusCode != null && statusCode >= 500) {
    return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
  }
  return '요청을 처리하지 못했습니다.';
}
