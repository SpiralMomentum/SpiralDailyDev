import 'package:adage_spark/features/adage/data/models/adage_quote_dto.dart';
import 'package:utils/utils.dart';

class AdageLocalDataSource {
  AdageLocalDataSource()
      : _seedQuotes = List<AdageQuoteDto>.from(_defaultQuotes),
        _customQuotes = [];

  final List<AdageQuoteDto> _seedQuotes;
  final List<AdageQuoteDto> _customQuotes;

  Result<List<AdageQuoteDto>> fetchQuotes() {
    return Success<List<AdageQuoteDto>>(
      List<AdageQuoteDto>.from(_customQuotes)..addAll(_seedQuotes),
    );
  }

  Result<AdageQuoteDto> addCustomQuote(AdageQuoteDto dto) {
    _customQuotes.add(dto);
    return Success(dto);
  }
}

const List<AdageQuoteDto> _defaultQuotes = [
  AdageQuoteDto(
    body: '끊임없는 연습은 평범한 재능을 비범하게 만든다.',
    reference:
        '“Practice isn\'t the thing you do once you\'re good.\nIt\'s the thing you do that makes you good.”\n- Malcolm Gladwell',
  ),
  AdageQuoteDto(
    body: '기회를 기다리기보다 작은 용기로 길을 만들어라.',
    reference:
        '“The most difficult thing is the decision to act, the rest is merely tenacity.”\n- Amelia Earhart',
  ),
  AdageQuoteDto(
    body: '생각에 머물지 말고 움직여라. 행동이 곧 너를 정의한다.',
    reference:
        '“You are what you do, not what you say you\'ll do.”\n- Carl Jung',
  ),
  AdageQuoteDto(
    body: '어제보다 나아지려는 한 걸음이 미래를 바꾼다.',
    reference:
        '“Do not wait to strike till the iron is hot; but make it hot by striking.”\n- William Butler Yeats',
  ),
  AdageQuoteDto(
    body: '실패는 반대가 아니라 성공으로 이어지는 구성 요소다.',
    reference:
        '“Failure is not the opposite of success; it\'s part of success.”\n- Arianna Huffington',
  ),
  AdageQuoteDto(
    body: '작은 성취를 찬찬히 쌓을 때 큰 꿈이 현실이 된다.',
    reference:
        '“Great things are done by a series of small things brought together.”\n- Vincent van Gogh',
  ),
];
