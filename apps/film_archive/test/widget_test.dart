import 'package:film_archive/app/film_archive_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Timeline builder UI renders', (tester) async {
    await tester.pumpWidget(FilmArchiveApp(apiKey: 'test'));

    expect(find.text('연도 범위를 선택하세요'), findsOneWidget);
    expect(find.text('타임라인 만들기'), findsOneWidget);
    expect(find.text('연도를 선택해 타임라인을 만들어보세요.'), findsOneWidget);
  });
}
