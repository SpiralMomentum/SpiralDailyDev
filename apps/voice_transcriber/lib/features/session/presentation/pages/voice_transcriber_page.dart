import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/voice_session_status.dart';
import '../../domain/value_objects/transcription_engine.dart';
import '../cubit/voice_session_cubit.dart';
import '../cubit/voice_session_state.dart';

class VoiceTranscriberPage extends StatefulWidget {
  const VoiceTranscriberPage({super.key});

  @override
  State<VoiceTranscriberPage> createState() => _VoiceTranscriberPageState();
}

class _VoiceTranscriberPageState extends State<VoiceTranscriberPage> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<VoiceSessionCubit>().initialize();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VoiceSessionCubit, VoiceSessionState>(
      listener: (context, state) {
        final result = state.result;
        if (result != null && _textController.text != result.text) {
          _textController.text = result.text;
        }

        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('세션 처리 중 오류가 발생했습니다: ${state.errorMessage}'),
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<VoiceSessionCubit>();
        final isRecording = state.status == VoiceSessionStatus.recording;
        final isProcessing = state.status == VoiceSessionStatus.processing;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Voice Transcriber'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SessionStatusBanner(status: state.status),
                  const SizedBox(height: 16),
                  _EngineDropdown(
                    current: state.engine,
                    onChanged: (engine) {
                      if (engine != null) {
                        cubit.selectEngine(engine);
                      }
                    },
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: state.autoCopyEnabled,
                    title: const Text('자동 클립보드 복사'),
                    subtitle: const Text('변환이 완료되면 텍스트를 즉시 클립보드에 복사합니다.'),
                    onChanged: (_) => cubit.toggleAutoCopy(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isProcessing
                              ? null
                              : () {
                                  if (isRecording) {
                                    cubit.completeSession();
                                  } else {
                                    cubit.startRecording();
                                  }
                                },
                          icon: Icon(isRecording ? Icons.stop : Icons.mic),
                          label: Text(isRecording ? '정지 및 변환' : '녹음 시작'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: state.result == null
                              ? null
                              : () async {
                                  await cubit.copyToClipboard(_textController.text);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('텍스트를 클립보드에 복사했습니다.'),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.copy),
                          label: const Text('복사하기'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (isProcessing) const LinearProgressIndicator(),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _textController,
                    minLines: 6,
                    maxLines: 12,
                    onChanged: cubit.updateTranscription,
                    decoration: InputDecoration(
                      labelText: '변환 결과 미리보기',
                      alignLabelWithHint: true,
                      hintText: '변환된 텍스트가 여기에 표시됩니다.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _SharingOptionChip(
                        icon: Icons.share,
                        label: '공유 옵션',
                        onTap: state.result == null
                            ? null
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('외부 공유는 플랫폼 채널에서 구현 예정입니다.'),
                                  ),
                                );
                              },
                      ),
                      _SharingOptionChip(
                        icon: Icons.settings_voice,
                        label: '음성 명령 등록',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('디바이스 음성 명령은 Shortcut 통합 단계에서 연동됩니다.'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '힌트',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('• “지피티, 이거 물어봐” 명령으로 빠르게 녹음을 시작하세요.'),
                  const Text('• 디바이스 숏컷을 등록하면 잠금 화면에서도 즉시 실행할 수 있습니다.'),
                  if (state.result?.engineLabel != null) ...[
                    const SizedBox(height: 12),
                    Text('선택된 엔진: ${state.result?.engineLabel ?? state.engine.label}'),
                    if (state.result?.copiedToClipboard == true)
                      const Text('결과가 자동으로 클립보드에 복사되었습니다.'),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SessionStatusBanner extends StatelessWidget {
  const _SessionStatusBanner({
    required this.status,
  });

  final VoiceSessionStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = () {
      switch (status) {
        case VoiceSessionStatus.idle:
          return '대기 중입니다. 음성 명령이나 버튼으로 녹음을 시작하세요.';
        case VoiceSessionStatus.recording:
          return '녹음 중... 말씀이 끝나면 정지 버튼을 눌러 주세요.';
        case VoiceSessionStatus.processing:
          return '변환 중입니다. 잠시만 기다려 주세요.';
        case VoiceSessionStatus.completed:
          return '변환이 완료되었습니다. 텍스트를 확인하고 공유하거나 편집하세요.';
        case VoiceSessionStatus.error:
          return '오류가 발생했습니다. 다시 시도해 주세요.';
      }
    }();

    final color = () {
      switch (status) {
        case VoiceSessionStatus.recording:
          return theme.colorScheme.errorContainer;
        case VoiceSessionStatus.processing:
          return theme.colorScheme.surfaceVariant;
        case VoiceSessionStatus.completed:
          return theme.colorScheme.primaryContainer;
        case VoiceSessionStatus.error:
          return theme.colorScheme.errorContainer;
        case VoiceSessionStatus.idle:
          return theme.colorScheme.secondaryContainer;
      }
    }();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}

class _EngineDropdown extends StatelessWidget {
  const _EngineDropdown({
    required this.current,
    required this.onChanged,
  });

  final TranscriptionEngine current;
  final ValueChanged<TranscriptionEngine?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<TranscriptionEngine>(
      value: current,
      decoration: const InputDecoration(
        labelText: '변환 엔진 선택',
        border: OutlineInputBorder(),
      ),
      items: TranscriptionEngine.values
          .map(
            (engine) => DropdownMenuItem<TranscriptionEngine>(
              value: engine,
              child: Text(engine.label),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _SharingOptionChip extends StatelessWidget {
  const _SharingOptionChip({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: enabled
              ? Theme.of(context).colorScheme.surfaceVariant
              : Theme.of(context).disabledColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
