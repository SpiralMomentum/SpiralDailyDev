import 'package:flutter/material.dart';
import 'package:voice_ai_assistant/src/assistant_controller.dart';

class VoiceAssistantApp extends StatelessWidget {
  const VoiceAssistantApp({super.key, this.controller});

  final AssistantController? controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pace AI',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xffa7f46a),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xff0d100f),
        fontFamily: 'sans-serif',
      ),
      home: AssistantHomePage(
        controller:
            controller ??
            AssistantController(
              audioFocus: DemoAudioFocusGateway(),
              speech: DemoSpeechGateway(),
              notes: MemoryNoteRepository(),
            ),
      ),
    );
  }
}

class AssistantHomePage extends StatefulWidget {
  const AssistantHomePage({required this.controller, super.key});
  final AssistantController controller;

  @override
  State<AssistantHomePage> createState() => _AssistantHomePageState();
}

class _AssistantHomePageState extends State<AssistantHomePage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    widget.controller.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _startConversation() async {
    try {
      await widget.controller.startConversation();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.controller.lastError ?? '다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
          child: Column(
            children: [
              _Header(earphonesConnected: controller.earphonesConnected),
              const SizedBox(height: 26),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _MusicCard(isDucked: controller.musicDucked),
                      const SizedBox(height: 32),
                      _VoiceOrb(
                        phase: controller.phase,
                        onTap: _startConversation,
                      ),
                      const SizedBox(height: 22),
                      Text(
                        _phaseTitle(controller.phase),
                        key: const Key('phaseTitle'),
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _phaseHint(controller.phase),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .55),
                          height: 1.45,
                        ),
                      ),
                      if (controller.transcript.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        _TranscriptCard(controller: controller),
                      ],
                    ],
                  ),
                ),
              ),
              _QuickMode(controller: controller),
            ],
          ),
        ),
      ),
    );
  }

  String _phaseTitle(AssistantPhase phase) => switch (phase) {
    AssistantPhase.ready => '말할 준비가 됐어요',
    AssistantPhase.listening => '듣고 있어요',
    AssistantPhase.thinking => '생각하고 있어요',
    AssistantPhase.speaking => '답변하는 중이에요',
  };

  String _phaseHint(AssistantPhase phase) => switch (phase) {
    AssistantPhase.ready => '이어폰 버튼을 길게 누르거나\n아래 버튼을 탭하세요',
    AssistantPhase.listening => '주변 소음을 줄이고 목소리에 집중하고 있어요',
    AssistantPhase.thinking => '말씀하신 내용을 정리하고 있어요',
    AssistantPhase.speaking => '답변이 끝나면 음악을 자동으로 되돌릴게요',
  };
}

class _Header extends StatelessWidget {
  const _Header({required this.earphonesConnected});
  final bool earphonesConnected;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xffa7f46a),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.graphic_eq, color: Color(0xff15200e)),
      ),
      const SizedBox(width: 12),
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PACE', style: TextStyle(fontWeight: FontWeight.w800)),
          Text('MOVE. THINK. CAPTURE.', style: TextStyle(fontSize: 9)),
        ],
      ),
      const Spacer(),
      _Pill(
        icon: Icons.headphones,
        label: earphonesConnected ? '연결됨' : '연결 안 됨',
      ),
    ],
  );
}

class _MusicCard extends StatelessWidget {
  const _MusicCard({required this.isDucked});
  final bool isDucked;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xff181c1a),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: .07)),
    ),
    child: Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xffe98149), Color(0xff6235a8)],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.landscape, color: Colors.white),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RUNNING FLOW',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Night Drive · Focus Mix',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        _Pill(
          icon: isDucked ? Icons.volume_down : Icons.equalizer,
          label: isDucked ? '볼륨 낮춤' : '재생 중',
        ),
      ],
    ),
  );
}

class _VoiceOrb extends StatelessWidget {
  const _VoiceOrb({required this.phase, required this.onTap});
  final AssistantPhase phase;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final active = phase != AssistantPhase.ready;
    return Semantics(
      button: true,
      label: active ? '음성 처리 중' : '음성 대화 시작',
      child: GestureDetector(
        key: const Key('voiceButton'),
        onTap: active ? null : () => onTap(),
        child: Container(
          width: 154,
          height: 154,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xffa7f46a).withValues(alpha: .12),
            border: Border.all(
              color: const Color(0xffa7f46a).withValues(alpha: .32),
              width: 10,
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? const Color(0xffc6ff95) : const Color(0xffa7f46a),
              boxShadow: const [
                BoxShadow(color: Color(0x55a7f46a), blurRadius: 28),
              ],
            ),
            child: Icon(
              phase == AssistantPhase.speaking ? Icons.graphic_eq : Icons.mic,
              size: 42,
              color: const Color(0xff17200f),
            ),
          ),
        ),
      ),
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  const _TranscriptCard({required this.controller});
  final AssistantController controller;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xff181c1a),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '내가 말한 내용',
          style: TextStyle(color: Color(0xffa7f46a), fontSize: 12),
        ),
        const SizedBox(height: 7),
        Text(controller.transcript),
        if (controller.latestNote?.audioPath != null) ...[
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.check_circle, size: 15, color: Color(0xffa7f46a)),
              SizedBox(width: 6),
              Text(
                '원본 음성과 텍스트를 저장했어요',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ] else if (controller.latestNote != null) ...[
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.check_circle, size: 15, color: Color(0xffa7f46a)),
              SizedBox(width: 6),
              Text(
                '텍스트 아이디어를 저장했어요 · 데모 모드',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _QuickMode extends StatelessWidget {
  const _QuickMode({required this.controller});
  final AssistantController controller;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xff181c1a),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const Icon(Icons.lightbulb_outline, color: Color(0xffa7f46a)),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '빠른 아이디어 기록',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Text(
                '말하면 AI가 자동으로 정리해요',
                style: TextStyle(fontSize: 10, color: Colors.white54),
              ),
            ],
          ),
        ),
        Switch(
          value: controller.saveAsIdea,
          onChanged: controller.isBusy
              ? null
              : (_) => controller.toggleIdeaMode(),
        ),
      ],
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xffa7f46a).withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xffa7f46a), size: 14),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: Color(0xffa7f46a), fontSize: 10),
        ),
      ],
    ),
  );
}
