import 'dart:math';

import '../entities/catalog.dart';

/// 시행마다 채널 문항 중 [count] 개를 무작위로 고른다. 순서는 원래 순서를 유지한다.
abstract final class QuestionSampler {
  static List<Question> sample(Channel channel, int count, Random random) {
    final indexes = List<int>.generate(channel.questions.length, (i) => i)
      ..shuffle(random);
    final chosen = indexes.take(min(count, indexes.length)).toList()..sort();
    return [for (final i in chosen) channel.questions[i]];
  }
}
