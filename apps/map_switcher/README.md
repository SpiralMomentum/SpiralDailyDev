# Map Switcher

Shared map experience demonstrating runtime provider swapping within the SpiralDailyDev mono-repository.

## Highlights

- Interactive OpenStreetMap implementation with panning, zooming, and marker overlays.
- 네이버 지도 Open API 연동(클라이언트 ID 설정 시 활성화)으로 실제 네이버 지도를 확인할 수 있습니다.
- Provider registry architecture that allows runtime switching between real SDK integrations and placeholder templates.
- Searchable location catalog with quick navigation controls that drive the active map provider.

## Naver Map Open API 설정

네이버 지도 제공자를 사용하려면 [네이버 클라우드 플랫폼](https://www.ncloud.com/)에서 발급한 클라이언트 ID(및 필요 시 시크릿)를 실행 시점에 전달해야 합니다.

1. `NAVER_MAP_CLIENT_ID`와 선택적으로 `NAVER_MAP_CLIENT_SECRET` 값을 준비합니다.
2. 앱을 실행할 때 아래와 같이 `--dart-define` 인자를 추가합니다.

```bash
flutter run \
  --dart-define=NAVER_MAP_CLIENT_ID=YOUR_CLIENT_ID \
  --dart-define=NAVER_MAP_CLIENT_SECRET=YOUR_CLIENT_SECRET
```

클라이언트 ID가 설정되지 않은 경우 기존과 동일하게 템플릿 설명 화면이 표시됩니다.
