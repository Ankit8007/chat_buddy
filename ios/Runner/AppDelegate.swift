import Flutter
import UIKit
import Firebase



import UIKit
import Flutter
import Firebase

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
  ) -> Bool {

    // Firebase init
    FirebaseApp.configure()

    // Notification delegate (FlutterAppDelegate already conforms)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    // Register plugins
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}


// @main
// @objc class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate {
//
//   override func application(
//     _ application: UIApplication,
//     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
//   ) -> Bool {
//
//     // Firebase initialization
//     FirebaseApp.configure()
//
//     // Notification delegate (iOS 10+)
//     if #available(iOS 10.0, *) {
//       UNUserNotificationCenter.current().delegate = self
//     }
//
//     // Register Flutter plugins
//     GeneratedPluginRegistrant.register(with: self)
//
//     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//   }
// }












//
//import Flutter
//import UIKit
//
//@main
//@objc class AppDelegate: FlutterAppDelegate {
//  override func application(
//    _ application: UIApplication,
//    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//  ) -> Bool {
//    GeneratedPluginRegistrant.register(with: self)
//    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//  }
//}
