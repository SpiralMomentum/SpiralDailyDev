import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../report/content_report.dart';
import '../domain/entities/evaluation.dart';
import 'bloc/attempt_bloc.dart';
import 'bloc/attempt_event.dart';
import 'bloc/attempt_state.dart';
import 'widgets/generating_view.dart';
import 'widgets/quiz_view.dart';
import 'widgets/result_view.dart';
import 'widgets/scene_recorder.dart';

/// 공유 프레임을 넘겨받아 공유를 끝내면 true. 공유 기능은 앱 조립 영역이 연결한다.
typedef FramesSharer = Future<bool> Function(List<CapturedFrame> frames, String caption);

/// 생성 대사 신고 창구(메일 앱)를 열면 true. 앱 조립 영역이 연결한다.
typedef ContentReporter = Future<bool> Function(EvaluationResult result);

class AttemptPage extends StatelessWidget {
  const AttemptPage({super.key, required this.createBloc, required this.shareFrames, this.reportContent});

  final AttemptBloc Function() createBloc;
  final FramesSharer shareFrames;

  /// null 이면 결과 화면에 신고 버튼을 두지 않는다.
  final ContentReporter? reportContent;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => createBloc()..add(const AttemptStarted()),
        child: _AttemptBody(shareFrames: shareFrames, reportContent: reportContent),
      );
}

class _AttemptBody extends StatelessWidget {
  const _AttemptBody({required this.shareFrames, this.reportContent});

  final FramesSharer shareFrames;
  final ContentReporter? reportContent;

  /// 메일 앱을 열지 못하면 신고 본문을 복사해 두고 보낼 주소를 알려 준다.
  Future<void> _report(BuildContext context, EvaluationResult result) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (await reportContent!(result)) return;
    await Clipboard.setData(ClipboardData(text: contentReportBody(result)));
    messenger.showSnackBar(SnackBar(content: Text(l10n.reportCopied(contentReportEmail))));
  }

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
                onReport: reportContent == null ? null : () => _report(context, state.result!),
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
