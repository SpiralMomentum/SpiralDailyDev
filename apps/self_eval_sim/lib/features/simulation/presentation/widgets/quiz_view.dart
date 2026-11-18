import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/catalog.dart';
import '../../domain/entities/text_book.dart';
import 'channel_art.dart';

class QuizView extends StatelessWidget {
  const QuizView({
    super.key,
    required this.channel,
    required this.text,
    required this.question,
    required this.current,
    required this.total,
    required this.onChoice,
  });

  final Channel channel;
  final TextBook text;
  final Question question;
  final int current;
  final int total;
  final ValueChanged<String> onChoice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        ChannelArt(art: channel.art),
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
                Text(
                  text.question(channel.id, question.id),
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
                        text.choice(channel.id, question.id, question.choices[i].id),
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
