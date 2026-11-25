/// 카이로스 앱 출시 상태.
enum KairosStatus { preLaunch, launched }

/// 빌드 시점 앱 설정. 출시 후 [kairosStatus]와 [kairosUrl]만 바꾼다.
class AppConfig {
  const AppConfig({this.kairosStatus = KairosStatus.preLaunch, this.kairosUrl});

  final KairosStatus kairosStatus;

  /// preLaunch: 알림 신청 페이지, launched: 스토어 URL. null이면 버튼을 숨긴다.
  final String? kairosUrl;
}
