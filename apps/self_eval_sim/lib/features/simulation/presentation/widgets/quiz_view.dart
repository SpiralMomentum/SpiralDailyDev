import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/quiz_question.dart';
import 'channel_art.dart';

/// 풀린 문항 하나를 그린다. 첫 질문([current] == 1)에만 질문 위에 도입 문장([intro])을 보인다.
class QuizView extends StatelessWidget {
  const QuizView({
    super.key,
    required this.art,
    required this.question,
    required this.intro,
    required this.current,
    required this.total,
    required this.onChoice,
  });

  final String art;
  final QuizQuestion question;
  final List<String> intro;
  final int current;
  final int total;
  final ValueChanged<String> onChoice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        ChannelArt(art: art),
        Container(color: Colors.black.withValues(alpha: 0.35)),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                  value: current / total,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.quizProgress(current, total),
                  key: const Key('quiz_progress'),
                  style: const TextStyle(color: Colors.white70),
                ),
                const Spacer(),
                // 도입이 길어도 질문과 선택지를 밀어내지 않게 남는 공간 안에서 스크롤한다.
                if (current == 1 && intro.isNotEmpty) ...[
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(
                        intro.join('\n'),
                        key: const Key('quiz_intro'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  question.text,
                  key: const Key('question_text'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                for (var i = 0; i < question.choices.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FilledButton(
                      key: Key('choice_$i'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.92),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                        alignment: Alignment.centerLeft,
                      ),
                      onPressed: () => onChoice(question.choices[i].id),
                      child: Text(
                        question.choices[i].text,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
