import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/report/content_report.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/evaluation.dart';

void main() {
  const result = EvaluationResult(
    channelId: 'wuxia',
    attemptIndex: 3,
    archetype: 1,
    title: '무당의 태극권사',
    manifestationForm: null,
    baseSource: NarrationSource.model,
    scenes: [
      Scene(kind: SceneKind.base, art: 'wuxia', place: '비무장', speaker: '검객', lines: ['첫 줄', '둘째 줄']),
    ],
  );

  test('신고 본문에 평가, 출처, 장면별 대사가 모두 들어간다', () {
    final body = contentReportBody(result);
    expect(body, contains('평가: 무당의 태극권사'));
    expect(body, contains('기본 대사 출처: model'));
    expect(body, contains('[base] 비무장 · 검객'));
    expect(body, contains('첫 줄\n둘째 줄'));
  });

  test('신고 메일 주소와 제목, 본문을 mailto 로 만든다 (공백은 %20)', () {
    final uri = contentReportUri(result);
    expect(uri.scheme, 'mailto');
    expect(uri.path, contentReportEmail);
    expect(uri.query, contains('subject=%5B%EB%88%84%EC%A0%81%20%ED%8F%89%EA%B0%80%5D'));
    expect(uri.query, isNot(contains('+')));
    expect(Uri.decodeComponent(uri.query), contains('첫 줄'));
  });
}
