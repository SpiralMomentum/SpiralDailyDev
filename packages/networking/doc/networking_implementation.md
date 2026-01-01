## 네트워킹 패키지 구현 전략

### 목표
- External 레이어에서 네트워크 세부 구현을 격리한다.
- 앱/피처는 통신 정책(헤더/토큰/타임아웃/로깅)을 공통으로 재사용한다.
- 실패/예외를 의미 단위로 정규화한다.
- Retrofit 서비스 정의를 서비스별로 모듈화한다.

---

### 패키지 위치
- `packages/networking`

---

### 폴더 구조
```
packages/networking/lib/
  networking.dart
  src/
    core/
      network_failure.dart
      network_exception.dart
    dio/
      dio_error_mapper.dart
      dio_provider.dart
      network_options.dart
      interceptors/
        dynamic_headers_interceptor.dart
        dynamic_query_interceptor.dart
    executor/
      network_executor.dart
    services/
      tmdb/
        tmdb_data_source.dart
        tmdb_data_source.g.dart
```

---

### 핵심 구성

#### 1) 공통 실패/예외 (core)
- `NetworkFailure` / `NetworkFailureType`: 타임아웃, 네트워크 없음, 서버 오류 등 의미 단위 실패.
- `NetworkException`: `NetworkFailure`를 포함해 상위 레이어가 일관된 실패로 처리 가능.

#### 2) Dio 구성 (dio)
- `NetworkOptions`: baseUrl, timeout, default headers/query, 동적 헤더/쿼리.
- `DioProvider`: 공통 옵션 + 인터셉터 + 로그 설정을 적용한 Dio 생성.
- `DynamicHeadersInterceptor`, `DynamicQueryInterceptor`: 토큰/공통 파라미터 자동 주입.
- `dio_error_mapper.dart`: `DioException`을 `NetworkFailure`로 정규화.

#### 3) 실행 래퍼 (executor)
- `NetworkExecutor.run`: 모든 네트워크 호출을 감싸고 `NetworkResult`로 성공/실패를 반환.

#### 4) 서비스별 Retrofit 정의 (services)
- 서비스별 DataSource를 Retrofit 인터페이스로 정의.
- 예: `TmdbDataSource`는 `HttpResponse<dynamic>`을 반환하여 파싱을 호출 측에서 제어.

---

### 사용 흐름 (Film Archive 기준)
1. `lib/app`에서 `NetworkOptions`로 공통 설정 구성.
2. `DioProvider`로 Dio 생성.
3. Retrofit 서비스(`TmdbDataSource`) 생성.
4. Data 레이어의 RemoteDataSource에서 `NetworkExecutor.run`으로 호출하고,
   응답을 DTO로 파싱한 뒤 도메인으로 변환.

---

### TMDB 서비스 규칙
- 위치: `packages/networking/lib/src/services/tmdb/tmdb_data_source.dart`
- Retrofit 인터페이스는 서비스별로 관리한다.
- 반환 타입은 `HttpResponse<dynamic>`로 두어, 앱별 DTO/파싱 전략을 선택 가능하게 한다.

---

### 에러 처리 규칙
- External: `DioException` -> `NetworkFailure` -> `NetworkException` -> `NetworkResult.Error`
- Data: `NetworkException` -> `Failure`(도메인) -> `Result.Error`
- Presentation/Domain은 예외를 직접 잡지 않는다.

---

### 생성 코드
- Retrofit 생성 파일은 같은 디렉터리에 위치한다.
- 생성 명령:
  - `cd packages/networking`
  - `dart run build_runner build --delete-conflicting-outputs`

---

### 확장 가이드
- 새 서비스 추가 시 `services/{service_name}` 하위에 Retrofit 인터페이스를 정의한다.
- 공통 헤더/토큰 정책은 `NetworkOptions.dynamicHeaders` 또는
  `DynamicHeadersInterceptor`로 확장한다.
- 공통 로깅/트레이싱은 `DioProvider`에서 인터셉터로 추가한다.
