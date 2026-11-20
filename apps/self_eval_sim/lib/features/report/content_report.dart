import 'package:url_launcher/url_launcher.dart';

import '../simulation/domain/entities/evaluation.dart';

/// 생성형 AI 대사 신고. 결과 화면의 대사와 출처를 메일로 개발자에게 보낸다.
/// (Google Play 생성형 AI 콘텐츠 정책: 앱 안에서 불쾌한 생성 콘텐츠를 신고할 수 있어야 한다)
const String contentReportEmail = 'spiraldailydev@gmail.com';

/// 신고 메일 본문. 순수 함수라 화면 없이 검증한다.
String contentReportBody(EvaluationResult result, {String appVersion = ''}) {
  final buffer = StringBuffer()
    ..writeln('[누적 평가 대사 신고]')
    ..writeln('문제가 된 내용과 이유를 적어 주세요:')
    ..writeln()
    ..writeln()
    ..writeln('---- 아래는 자동으로 첨부된 결과입니다 ----')
    ..writeln('채널: ${result.channelId} / 회차: ${result.attemptIndex}')
    ..writeln('평가: ${result.title}')
    ..writeln('기본 대사 출처: ${result.baseSource.name}'
        '${result.manifestationSource == null ? '' : ' / 발현 대사 출처: ${result.manifestationSource!.name}'}');
  if (appVersion.isNotEmpty) buffer.writeln('앱 버전: $appVersion');
  for (final scene in result.scenes) {
    buffer
      ..writeln()
      ..writeln('[${scene.kind.name}] ${scene.place} · ${scene.speaker}');
    for (final line in scene.lines) {
      buffer.writeln(line);
    }
  }
  return buffer.toString();
}

Uri contentReportUri(EvaluationResult result) => Uri(
      scheme: 'mailto',
      path: contentReportEmail,
      query: _encodeQuery({
        'subject': '[누적 평가] 대사 신고 - ${result.title}',
        'body': contentReportBody(result),
      }),
    );

// Uri(queryParameters:) 는 공백을 '+' 로 바꿔 메일 앱에 그대로 보이므로 %20 으로 직접 인코딩한다.
String _encodeQuery(Map<String, String> params) =>
    params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');

/// 메일 앱을 열면 true. 메일 앱이 없으면 false 를 돌려 화면이 대체 경로(본문 복사)를 쓰게 한다.
Future<bool> openContentReportMail(EvaluationResult result) async {
  try {
    return await launchUrl(contentReportUri(result), mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
