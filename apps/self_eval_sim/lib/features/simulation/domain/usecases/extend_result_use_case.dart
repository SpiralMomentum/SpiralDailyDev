import '../entities/catalog.dart';
import '../entities/evaluation.dart';
import '../entities/text_book.dart';
import '../policies/result_composer.dart';

/// 보상형 광고 시청 보상으로 결과 장면을 확장한다.
class ExtendResultUseCase {
  const ExtendResultUseCase();

  EvaluationResult call(EvaluationResult result, Channel channel, TextBook text) =>
      ResultComposer.extend(result, channel, text);
}
