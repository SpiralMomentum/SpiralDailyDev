import 'dart:math';

import '../entities/catalog.dart';
import '../policies/question_sampler.dart';

/// 이번 시행에 낼 문항을 고른다.
class StartAttemptUseCase {
  const StartAttemptUseCase(this._random);

  final Random _random;

  List<Question> call(Channel channel, int questionsPerAttempt) =>
      QuestionSampler.sample(channel, questionsPerAttempt, _random);
}
