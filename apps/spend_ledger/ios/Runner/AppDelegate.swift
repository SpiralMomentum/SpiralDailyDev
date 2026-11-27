import Flutter
import UIKit
import UserNotifications
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// 화면(씬)과 함께 만들어지는 앱 엔진이 준비됐는지.
  private var hasImplicitEngine = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 알림 액션 isolate·헤드리스 엔진에서도 플러그인을 쓸 수 있게 한다.
    // 단축어로 화면 없이 시작될 때도 등록되도록 앱 시작 시점에 설정한다.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    hasImplicitEngine = true
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    IngestDiagnostics.register(messenger: engineBridge.applicationRegistrar.messenger())
  }

  /// 알림 액션으로 화면 없이 시작되면 플러그인을 등록한 엔진이 없어 응답이 버려진다.
  /// 그때는 헤드리스 엔진을 먼저 띄워(플러그인 등록) 응답을 받게 한다.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    MainActor.assumeIsolated {
      if !hasImplicitEngine && !HeadlessIngest.shared.hasEngine {
        HeadlessIngest.shared.startEngineIfNeeded()
      }
    }
    super.userNotificationCenter(
      center, didReceive: response, withCompletionHandler: completionHandler)
  }
}
