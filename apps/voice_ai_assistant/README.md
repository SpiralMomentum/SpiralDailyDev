# Pace Voice AI sample

운동 흐름을 유지하며 음성으로 대화하고 아이디어를 기록하는 Flutter 샘플입니다.

## 포함된 흐름

- 큰 단일 음성 버튼과 이어폰 원격 호출을 가정한 핸즈프리 진입점
- AI 호출 시 음악 ducking, 종료/오류 시 기존 재생 상태 자동 복원
- 소음 억제 옵션을 켠 STT 요청과 이어폰 대상 TTS 응답
- 텍스트, 원본 음성 경로, AI 제목을 함께 저장하는 아이디어 모드
- `ready → listening → thinking → speaking → ready` 상태 모델

현재 gateway 구현은 화면 흐름을 확인하기 위한 데모이며 실제 오디오 파일을
만들지 않습니다. 따라서 데모에서는 텍스트만 저장되었다고 명확히 표시합니다. 실제 제품에서는
`AudioFocusGateway`, `SpeechGateway`, `NoteRepository`를 Android AudioFocus / iOS
AVAudioSession, 온디바이스 또는 서버 STT/TTS, 영속 저장소 어댑터로 교체합니다.

```bash
flutter pub get
flutter run
flutter test
```
