# SpiralDailyDev

Flutter 기반의 Mono Repo 베이스, Clean Architecture 룰을 따르는 프로젝트입니다.

## Repository Structure
- `apps/`
  - `daily_memo/`
  - `exchange_rate_calculator/`
  - `spiral_trade_show/`
- `packages/`
  - `ui_components/`
  - `utils/`

## Services Overview
| Service | Summary | Highlights |
| --- | --- | --- |
| Daily Memo | 간단한 메모를 작성하고 관리하는 개인용 노트 앱 | sqflite 로컬 DB를 통해 메모 CRUD를 수행하며 BLoC 로직으로 상태를 관리하고 GoRouter 로 화면을 구성합니다. |
| Exchange Rate Calculator | 환율 조회 및 계산 기능을 제공하는 학습용 앱 | 싱글톤 저장소가 외부 API에서 환율 정보를 가져오고 Adapter 패턴으로 다양한 데이터 소스를 통합하며 GoRouter 기반 라우팅을 제공합니다. |
| Spiral Trade Show | 서울시 전시 정보를 보여주는 홍보용 앱 | Dio HTTP 클라이언트와 보안 키를 활용해 공공 데이터 포털에서 전시 정보를 수집하고 Cubit 패턴으로 UI 상태를 갱신합니다. |
| Voice Transcriber | 음성 녹음과 텍스트 변환을 지원하는 실험용 앱 | Clean Architecture 기반의 세션 단위 UseCase 설계를 통해 A/B 테스트용 변환 엔진(OpenAI vs 자체 모델)을 런타임에서 전환하고 자동 클립보드 복사를 제공합니다. |

## Daily Memo App
- `sqflite`를 사용하는 `SQLHelper`를 통해 로컬 데이터베이스에 메모를 저장하고 CRUD 기능을 제공합니다.
- 메모 흐름은 `MemoBloc`이 이벤트별 로직을 처리하면서 상태를 관리하며, 라우팅은 `GoRouter` 기반으로 구성되어 있습니다.

## Exchange Rate Calculator
- `ExchangeRepositoryImpl`은 싱글톤으로 구현되어 앱 시작 시 환율 데이터를 선로드합니다.
- `ExchangeAdapterApiClient`가 어댑터 패턴으로 Github 환율 데이터를 한국 수출입은행 형식으로 변환합니다.
- 라우팅은 `GoRouter` 기반 `MaterialApp.router`로 설정되어 있습니다.

## Spiral Trade Show
- `InfoShelfRepositoryImpl`이 서울시 오픈 API에서 전시 정보를 가져와 도메인 모델로 변환합니다.
- `TradeShowApp`은 Cubit을 활용한 `MainShelfPage`를 통해 섹션별 전시 정보를 표시합니다.

## Shared Packages
- `packages/ui_components`: 공용 UI 위젯과 카드 컴포넌트를 제공합니다.
- `packages/utils`: 서비스 간에서 공유할 수 있는 유틸리티 로직을 담을 공간입니다.

## 배포 자동화 개요
- `release.yaml`: 각 앱의 스토어 메타데이터, 자동화 옵션(아이콘 생성, 스크린샷 캡처) 및 Fastlane 레인 정보를 정의한 중앙 설정 파일입니다.
- `store_metadata/`: 스토어 등록에 필요한 JSON/YAML 템플릿과 서비스별 메타데이터 파일을 보관합니다.
- `tools/release/`: `publisher.py` 스크립트를 통해 `release.yaml`을 읽고 아이콘 생성 → 스크린샷 캡처 → 빌드 → Fastlane 실행을 순차적으로 자동화합니다.
