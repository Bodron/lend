import Flutter
import FirebaseMessaging
import GoogleMaps
import StripeIdentity
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var identityInProgress = false
  private var pdfExportSession: PdfExportSession?
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
    let downloadsChannel = FlutterMethodChannel(
      name: "lend/downloads",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    downloadsChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "savePdfWithPicker" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let self = self,
            let arguments = call.arguments as? [String: Any],
            let rawName = arguments["name"] as? String,
            let bytes = arguments["bytes"] as? FlutterStandardTypedData,
            let presenter = self.identityPresenter() else {
        result(FlutterError(code: "PDF_EXPORT_UNAVAILABLE", message: "Could not open Files", details: nil))
        return
      }
      guard self.pdfExportSession == nil else {
        result(FlutterError(code: "PDF_EXPORT_BUSY", message: "A file is already being saved", details: nil))
        return
      }
      let safeName = (rawName as NSString).lastPathComponent
      let fileName = safeName.lowercased().hasSuffix(".pdf") ? safeName : "\(safeName).pdf"
      let temporaryDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
      let fileURL = temporaryDirectory.appendingPathComponent(fileName)
      do {
        try FileManager.default.createDirectory(
          at: temporaryDirectory,
          withIntermediateDirectories: true
        )
        try bytes.data.write(to: fileURL, options: .atomic)
      } catch {
        try? FileManager.default.removeItem(at: temporaryDirectory)
        result(FlutterError(code: "PDF_EXPORT_FAILED", message: "Could not prepare PDF", details: nil))
        return
      }
      let session = PdfExportSession(temporaryDirectory: temporaryDirectory) { [weak self] savedPath in
        self?.pdfExportSession = nil
        result(savedPath)
      }
      self.pdfExportSession = session
      session.present(fileURL: fileURL, from: presenter)
    }
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
    let activeScene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first(where: { $0.activationState == .foregroundActive })
    let root = activeScene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
      ?? window?.rootViewController
    var presenter = root
    while let presented = presenter?.presentedViewController {
      presenter = presented
    }
    return presenter
  }
}

private final class PdfExportSession: NSObject, UIDocumentPickerDelegate {
  private let temporaryDirectory: URL
  private let completion: (String?) -> Void
  private var finished = false

  init(temporaryDirectory: URL, completion: @escaping (String?) -> Void) {
    self.temporaryDirectory = temporaryDirectory
    self.completion = completion
  }

  func present(fileURL: URL, from presenter: UIViewController) {
    let picker = UIDocumentPickerViewController(forExporting: [fileURL], asCopy: true)
    picker.delegate = self
    presenter.present(picker, animated: true)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    finish(with: nil)
  }

  func documentPicker(
    _ controller: UIDocumentPickerViewController,
    didPickDocumentsAt urls: [URL]
  ) {
    finish(with: urls.first?.path)
  }

  private func finish(with savedPath: String?) {
    guard !finished else { return }
    finished = true
    try? FileManager.default.removeItem(at: temporaryDirectory)
    completion(savedPath)
  }
}
