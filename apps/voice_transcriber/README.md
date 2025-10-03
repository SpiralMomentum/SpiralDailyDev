# Voice Transcriber Service

모노레포 내 신규 서비스인 **Voice Transcriber** 는 음성 녹음 → 텍스트 변환 → 클립보드/공유 흐름을 하나의 화면에서 제공하는 실험용 앱입니다. 최종 사용자는 음성 명령이나 디바이스 숏컷을 통해 녹음을 시작하고, 변환된 텍스트를 자동 복사 또는 공유 옵션으로 즉시 활용할 수 있습니다.

## 아키텍처 개요

- **Clean Architecture** 를 기반으로 Presentation / Domain / Data 계층을 분리했습니다.
- `SpeechToTextGateway` 인터페이스 하나만으로 외부(앱)에서는 동일한 변환 진입점을 사용하도록 설계했습니다.
- `VoiceSessionSettingsRepository` 를 통해 A/B 테스트용 변환 엔진(OpenAI vs 자체 모델)을 런타임에서 교체할 수 있습니다.
- 모든 의존성은 `VoiceTranscriberDependencies.bootstrap()` 에서 조합하여 테스트와 배포 환경을 쉽게 분기할 수 있도록 했습니다.

```
VoiceTranscriberApp
 └─ VoiceSessionCubit (Presentation)
     ├─ StartRecordingUseCase
     ├─ CompleteSessionUseCase
     │    ├─ AudioRecorderRepository (Data → FakeAudioRecorderDataSource)
     │    ├─ SpeechToTextGateway (Data → FakeOpenAi/FakeLocal)
     │    └─ ClipboardRepository (플랫폼 채널)
     └─ VoiceSessionSettingsRepository (Data → In-memory)
```

## 기능 흐름

1. **녹음 시작**: `VoiceSessionCubit.startRecording()` → `StartRecordingUseCase` → `AudioRecorderRepository`
2. **녹음 종료 & 변환**: `VoiceSessionCubit.completeSession()` → `CompleteSessionUseCase`
   - 선택된 엔진 정보를 Settings Repository에서 가져옵니다.
   - 변환이 완료되면 자동 클립보드 복사 여부를 확인하고 실행합니다.
3. **결과 미리보기/편집**: `TextField` 를 통해 변환 결과를 즉시 수정할 수 있습니다.
4. **클립보드 & 공유**: 수동 복사 버튼, 공유 옵션(Stub) 버튼을 제공합니다.

## Stub 데이터 소스

현재 레포에는 외부 API 키가 포함되지 않으므로 `Fake*` 데이터 소스를 사용하여 흐름만 검증합니다. 실제 배포 단계에서는 다음과 같이 교체할 수 있습니다.

| 인터페이스 | Stub 구현 | 실제 구현 교체 포인트 |
| --- | --- | --- |
| `AudioRecorderRepository` | `FakeAudioRecorderDataSource` | `flutter_sound` 또는 플랫폼 채널 기반 Recorder |
| `SpeechToTextGateway` | `FakeOpenAiSpeechToTextDataSource`, `FakeLocalSpeechToTextDataSource` | OpenAI API 연동 Adapter, On-device 모델 Runner |
| `ClipboardRepository` | `ClipboardRepositoryImpl` | 현재도 실환경 사용 가능 |

## 근거 있는 개선 사항

- 기존 서비스들은 화면/로직이 1:1로 묶여 있는 경우가 많았는데, 이번 서비스는 **세션 단위 UseCase** 중심으로 상태를 관리해 장기적인 엔진 교체에 대비했습니다.
- `VoiceSessionState` 는 `autoCopyEnabled`, `engine` 등 환경 설정 값을 함께 들고 있어 UI가 별도 Storage를 의존하지 않아도 됩니다.
- A/B 테스트를 위한 엔진 전환을 Dropdown UI로 제공하고, Settings Repository에서 현재 선택을 단일화하였습니다.
- README 수준에서 Stub → 실제 구현 교체 지점을 명확하게 기록하여 온보딩 시간을 단축했습니다.

## 향후 과제

- 플랫폼별 음성 명령/Shortcut 연동 (iOS Shortcuts, Android Quick Actions)
- 외부 공유를 위한 Share Sheet 통합
- 실제 음성 → 텍스트 모델 연동과 Latency 측정
- 프라이버시 옵션(로컬 저장 여부, 자동 삭제 정책) 추가
