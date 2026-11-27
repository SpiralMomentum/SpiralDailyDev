/// 공백 제거·소문자 후 둘 다 비어 있지 않고 한쪽이 다른 쪽을 포함하면 같은 상대.
bool merchantMatches(String a, String b) {
  final x = _normalize(a);
  final y = _normalize(b);
  if (x.isEmpty || y.isEmpty) return false;
  return x.contains(y) || y.contains(x);
}

String _normalize(String s) => s.replaceAll(RegExp(r'\s+'), '').toLowerCase();
