import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import 'bloc/attempt_bloc.dart';
import 'bloc/attempt_event.dart';
import 'bloc/attempt_state.dart';
import 'widgets/generating_view.dart';
import 'widgets/quiz_view.dart';
import 'widgets/result_view.dart';
import 'widgets/scene_recorder.dart';

/// 공유 프레임을 넘겨받아 공유를 끝내면 true. 공유 기능은 앱 조립 영역이 연결한다.
typedef FramesSharer = Future<bool> Function(List<CapturedFrame> frames, String caption);

class AttemptPage extends StatelessWidget {
  const AttemptPage({super.key, required this.createBloc, required this.shareFrames});

  final AttemptBloc Function() createBloc;
  final FramesSharer shareFrames;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => createBloc()..add(const AttemptStarted()),
        child: _AttemptBody(shareFrames: shareFrames),
      );
}

class _AttemptBody extends StatelessWidget {
  const _AttemptBody({required this.shareFrames});

  final FramesSharer shareFrames;

  Future<void> _share(BuildContext context, AttemptState state) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = state.result!;
    final frames = await SceneRecorder.record(
      context,
      result: result,
      titleLabel: l10n.resultTitleLabel,
      message: l10n.shareMaking,
    );
    if (frames == null || frames.isEmpty) return;
    final ok = await shareFrames(frames, '${l10n.resultTitleLabel} · ${result.title}');
    if (!ok) messenger.showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AttemptBloc>();
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<AttemptBloc, AttemptState>(
        builder: (context, state) => switch (state.phase) {
          AttemptPhase.quiz => state.currentQuestion == null
              ? const SizedBox.shrink()
              : QuizView(
                  key: ValueKey('quiz_${state.answers.length}'),
                  art: state.art,
                  question: state.currentQuestion!,
                  intro: state.intro,
                  current: state.answers.length + 1,
                  total: state.questions.length,
                  onChoice: (id) => bloc.add(ChoiceSelected(id)),
                ),
          AttemptPhase.generating => GeneratingView(
              art: state.art,
              adStatus: state.adStatus,
              onWatchAd: () => bloc.add(const AdWatchRequested()),
              onSkipAd: () => bloc.add(const AdSkipped()),
            ),
          AttemptPhase.result => SafeArea(
              child: ResultView(
                key: ValueKey('result_${state.result!.attemptIndex}'),
                result: state.result!,
                onShare: () => _share(context, state),
                onAgain: () => bloc.add(const AttemptStarted()),
                onHome: () => Navigator.of(context).pop(),
              ),
            ),
          AttemptPhase.failure => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.commonError,
                    key: const Key('attempt_error'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.resultHome),
                  ),
                ],
              ),
            ),
        },
      ),
    );
  }
}
