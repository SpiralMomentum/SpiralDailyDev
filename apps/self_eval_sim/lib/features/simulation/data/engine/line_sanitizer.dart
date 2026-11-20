/// 모델 출력을 대사 줄로 정리하는 순수 함수 모음.
/// 형식 이탈(번호, 이름표, 따옴표, 특수 토큰)을 걷어내고, 규칙 위반 줄은 버린다.
abstract final class LineSanitizer {
  static final _specialTokens = RegExp(r'<\|?[^>\n]{0,40}\|?>');
  static final _bullet = RegExp(r'^\s*(?:[-*•·]|\d+[.)]|[①-⑩])\s*');
  static final _label = RegExp(r'^[^:：\n]{1,12}[:：]\s*');
  static const _quotes = '"\'“”‘’「」『』';
  static final _emphasis = RegExp(r'\*{1,2}([^*\n]+)\*{1,2}');

  static String _stripQuotes(String s) {
    var t = s.trim();
    while (t.length >= 2 &&
        _quotes.contains(t[0]) &&
        _quotes.contains(t[t.length - 1])) {
      t = t.substring(1, t.length - 1).trim();
    }
    return t;
  }

  static String cleanLine(String line) => _stripQuotes(
    line
        .replaceFirst(_bullet, '')
        .replaceFirst(_label, '')
        .replaceAllMapped(_emphasis, (m) => m[1]!)
        .trim(),
  );

  static final _tail = RegExp(r'''[\s.!?…~,'"」』)]+$''');

  /// 말끝 검사용: 끝의 문장부호와 따옴표를 뗀다.
  static String _trimEnd(String line) => line.replaceFirst(_tail, '');

  static final _nonLetter = RegExp(r'''[\s.,!?~"'·…]''');

  static String _compact(String s) => s.replaceAll(_nonLetter, '');

  /// [a] 와 [b] 가 공백과 문장부호를 빼고 [length] 글자 이상 이어서 겹치면 true.
  static bool overlaps(String a, String b, int length) {
    final x = _compact(a);
    final y = _compact(b);
    if (x.length < length || y.length < length) return false;
    for (var i = 0; i + length <= x.length; i++) {
      if (y.contains(x.substring(i, i + length))) return true;
    }
    return false;
  }

  /// 정리한 줄 목록. [maxLength] 의 1.5배를 넘는 줄, 결과 이름이 든 줄, 금지 패턴 줄, 중복,
  /// 말투 예시를 그대로 옮긴 줄([avoid]), [echoes] 중 하나와 [echoLength] 글자 이상 겹치는
  /// 줄(칭호나 질문 문장을 되읽는 줄)은 버린다.
  static List<String> clean(
    String raw, {
    required String title,
    required int maxLength,
    required int maxLines,
    List<RegExp> banned = const [],
    List<String> avoid = const [],
    List<String> echoes = const [],
    int echoLength = 9,
    RegExp? ending,
  }) {
    final seen = <String>{...avoid.map(cleanLine)};
    return raw
        .replaceAll(_specialTokens, '')
        .split('\n')
        .map(cleanLine)
        .where((l) => l.isNotEmpty)
        .where((l) => !l.contains(title))
        .where((l) => l.runes.length <= (maxLength * 1.5).ceil())
        .where((l) => !banned.any((p) => p.hasMatch(l)))
        .where((l) => !echoes.any((e) => overlaps(l, e, echoLength)))
        .where((l) => ending == null || ending.hasMatch(_trimEnd(l)))
        .where(seen.add)
        .take(maxLines)
        .toList();
  }
}
