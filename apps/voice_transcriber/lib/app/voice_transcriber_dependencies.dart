import '../features/session/data/datasources/fake_audio_recorder_datasource.dart';
import '../features/session/data/datasources/fake_local_speech_to_text_datasource.dart';
import '../features/session/data/datasources/fake_openai_speech_to_text_datasource.dart';
import '../features/session/data/repositories/audio_recorder_repository_impl.dart';
import '../features/session/data/repositories/clipboard_repository_impl.dart';
import '../features/session/data/repositories/speech_to_text_gateway_impl.dart';
import '../features/session/data/repositories/voice_session_settings_repository_impl.dart';
import '../features/session/domain/entities/voice_session_status.dart';
import '../features/session/domain/usecases/complete_session_use_case.dart';
import '../features/session/domain/usecases/copy_to_clipboard_use_case.dart';
import '../features/session/domain/usecases/load_session_settings_use_case.dart';
import '../features/session/domain/usecases/select_engine_use_case.dart';
import '../features/session/domain/usecases/start_recording_use_case.dart';
import '../features/session/domain/usecases/toggle_auto_copy_use_case.dart';
import '../features/session/domain/value_objects/transcription_engine.dart';
import '../features/session/presentation/cubit/voice_session_cubit.dart';
import '../features/session/presentation/cubit/voice_session_state.dart';

class VoiceTranscriberDependencies {
  VoiceTranscriberDependencies._(this.sessionCubit);

  factory VoiceTranscriberDependencies.bootstrap() {
    final settingsRepository = VoiceSessionSettingsRepositoryImpl();
    final audioRecorderRepository = AudioRecorderRepositoryImpl(
      FakeAudioRecorderDataSource(),
    );
    final speechGateway = SpeechToTextGatewayImpl(
      FakeOpenAiSpeechToTextDataSource(),
      FakeLocalSpeechToTextDataSource(),
      settingsRepository,
    );
    final clipboardRepository = ClipboardRepositoryImpl();

    final startRecording = StartRecordingUseCase(audioRecorderRepository);
    final completeSession = CompleteSessionUseCase(
      audioRecorderRepository,
      speechGateway,
      clipboardRepository,
      settingsRepository,
    );
    final toggleAutoCopy = ToggleAutoCopyUseCase(settingsRepository);
    final loadSettings = LoadSessionSettingsUseCase(settingsRepository);
    final selectEngine = SelectEngineUseCase(settingsRepository);
    final copyToClipboard = CopyToClipboardUseCase(clipboardRepository);

    final cubit = VoiceSessionCubit(
      const VoiceSessionState(
        status: VoiceSessionStatus.idle,
        engine: TranscriptionEngine.openAi,
      ),
      startRecording,
      completeSession,
      toggleAutoCopy,
      loadSettings,
      selectEngine,
      copyToClipboard,
    );

    return VoiceTranscriberDependencies._(cubit);
  }

  final VoiceSessionCubit sessionCubit;
}
