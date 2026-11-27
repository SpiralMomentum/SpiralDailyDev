/// 공백 제거·소문자 후 둘 다 비어 있지 않고 한쪽이 다른 쪽을 포함하면 같은 상대.
bool merchantMatches(String a, String b) {
  final x = _normalize(a);
  final y = _normalize(b);
  if (x.isEmpty || y.isEmpty) return false;
  return x.contains(y) || y.contains(x);
}

/// 중복 판정용 상대 비교. 상대를 찾지 못한 문자(빈 상대)끼리도 같은 상대로 본다.
/// 취소 원거래 찾기에는 쓰지 않는다(빈 상대로 엉뚱한 거래를 취소하지 않도록).
bool sameCounterpartyForDuplicate(String a, String b) =>
    (_normalize(a).isEmpty && _normalize(b).isEmpty) || merchantMatches(a, b);

String _normalize(String s) => s.replaceAll(RegExp(r'\s+'), '').toLowerCase();
