import 'parser.dart';

/// 문자의 형식 지문. 가맹점·금액·시각이 달라도 같은 양식이면 같은 값이 된다.
String formatSignature(String text, String? sender) {
  final shape = contentLines(text).map(_lineShape).join('/');
  return '${sender ?? ''}|$shape';
}

String _lineShape(String line) {
  final code = StringBuffer();
  if (containsAmount(line)) code.write('A');
  if (containsDateTime(line)) code.write('D');
  final keyword = firstKindKeyword(line);
  if (keyword != null) code.write(keyword);
  return code.isEmpty ? 'T' : code.toString();
}
