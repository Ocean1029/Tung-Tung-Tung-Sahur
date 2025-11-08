import UIKit
import Flutter
import flutter_local_notifications
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // This is required to make any communication available in the action isolate.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    GMSServices.provideAPIKey("AIzaSyDeCACODP01royg_alJUiLPtig5iawQwHs")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // 處理 URL Scheme（例如 runcity://nfc?tag=station_001）
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    // 將 URL 傳遞給 Flutter
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.yu.townpass/deep_link",
        binaryMessenger: controller.binaryMessenger
      )
      channel.invokeMethod("handleDeepLink", arguments: url.absoluteString)
    }
    return true
  }
}
