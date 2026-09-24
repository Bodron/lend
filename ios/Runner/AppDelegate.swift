import Flutter
import FirebaseMessaging
import GoogleMaps
import StripeIdentity
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var identityInProgress = false
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !apiKey.isEmpty,
       !apiKey.hasPrefix("$(") {
      GMSServices.provideAPIKey(apiKey)
    }

    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    application.registerForRemoteNotifications()
    return launched
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let identityChannel = FlutterMethodChannel(
      name: "lend/stripe_identity",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    identityChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "presentIdentity" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let arguments = call.arguments as? [String: String],
            let sessionId = arguments["sessionId"], !sessionId.isEmpty,
            let secret = arguments["ephemeralKeySecret"], !secret.isEmpty else {
        result(FlutterError(code: "INVALID_SESSION", message: "Stripe Identity session is missing", details: nil))
        return
      }
      guard let self = self else { return }
      guard !self.identityInProgress else {
        result(FlutterError(code: "ALREADY_OPEN", message: "Stripe Identity is already open", details: nil))
        return
      }
      guard let presenter = self.identityPresenter() else {
        result(FlutterError(code: "NO_PRESENTER", message: "Identity screen is unavailable", details: nil))
        return
      }
      self.identityInProgress = true
      let logo = UIImage(named: "LaunchImage") ?? UIImage(systemName: "person.crop.rectangle") ?? UIImage()
      let sheet = IdentityVerificationSheet(
        verificationSessionId: sessionId,
        ephemeralKeySecret: secret,
        configuration: .init(brandLogo: logo)
      )
      sheet.present(from: presenter) { [weak self] verificationResult in
        self?.identityInProgress = false
        switch verificationResult {
        case .flowCompleted:
          result("completed")
        case .flowCanceled:
          result("canceled")
        case .flowFailed(let error):
          result(FlutterError(code: "IDENTITY_FAILED", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  private func identityPresenter() -> UIViewController? {
    let root = window?.rootViewController ?? UIApplication.shared.connectedScenes
      .compactMap { ($0 as? UIWindowScene)?.windows.first(where: { $0.isKeyWindow })?.rootViewController }
      .first
    var presenter = root
    while let presented = presenter?.presentedViewController {
      presenter = presented
    }
    return presenter
  }
}
