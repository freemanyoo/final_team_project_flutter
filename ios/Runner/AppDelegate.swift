import Flutter
import UIKit
import GoogleMaps  // Google Maps SDK 추가

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps API 키 초기화
    // ⚠️ Android와 동일한 API 키 사용
    GMSServices.provideAPIKey("AIzaSyBh8233jiBHLw9mjtOA9Y5KhM0sLqKqLg0")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
