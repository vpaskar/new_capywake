import AVFoundation
import CoreMotion
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CapyStepCounter") {
      StepCounterChannel.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CapyCameraAccess") {
      CameraAccessChannel.register(with: registrar)
    }
  }
}

/// The step sensor for Step Quest: CMPedometer, counted from when the game
/// starts listening. The method and event names match `PlatformStepSensor`.
final class StepCounterChannel: NSObject, FlutterStreamHandler {
  private let pedometer = CMPedometer()
  private var sink: FlutterEventSink?
  private var delivered = 0
  private var session = 0

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = StepCounterChannel()
    FlutterMethodChannel(name: "capywake/steps", binaryMessenger: registrar.messenger())
      .setMethodCallHandler(instance.handle)
    FlutterEventChannel(name: "capywake/steps/events", binaryMessenger: registrar.messenger())
      .setStreamHandler(instance)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isAvailable":
      result(CMPedometer.isStepCountingAvailable())
    case "authorization":
      result(Self.authorizationName())
    case "requestAuthorization":
      // A one-minute query is how CoreMotion shows its Motion & Fitness prompt.
      let now = Date()
      pedometer.queryPedometerData(from: now.addingTimeInterval(-60), to: now) { _, _ in
        DispatchQueue.main.async { result(Self.authorizationName()) }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func authorizationName() -> String {
    switch CMPedometer.authorizationStatus() {
    case .authorized: return "authorized"
    case .notDetermined: return "notDetermined"
    case .denied: return "denied"
    case .restricted: return "restricted"
    @unknown default: return "restricted"
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    sink = events
    delivered = 0
    session += 1
    let current = session
    pedometer.startUpdates(from: Date()) { [weak self] data, error in
      let total = data?.numberOfSteps.intValue
      DispatchQueue.main.async {
        // A late update from a stopped session would replay its old total.
        guard let self, current == self.session, let sink = self.sink else { return }
        guard let total, error == nil else {
          sink(FlutterError(code: "pedometer", message: error?.localizedDescription, details: nil))
          return
        }
        let fresh = total - self.delivered
        if fresh > 0 {
          self.delivered = total
          sink(fresh)
        }
      }
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    pedometer.stopUpdates()
    session += 1
    sink = nil
    return nil
  }
}

/// Camera access for QR Treasure Hunt. The scanner itself is mobile_scanner;
/// this only reads and asks for permission. Names match `PlatformCameraAccess`.
enum CameraAccessChannel {
  static func register(with registrar: FlutterPluginRegistrar) {
    FlutterMethodChannel(name: "capywake/camera", binaryMessenger: registrar.messenger())
      .setMethodCallHandler { call, result in
        switch call.method {
        case "isAvailable":
          result(AVCaptureDevice.default(for: .video) != nil)
        case "authorization":
          result(authorizationName())
        case "requestAuthorization":
          AVCaptureDevice.requestAccess(for: .video) { _ in
            DispatchQueue.main.async { result(authorizationName()) }
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
  }

  private static func authorizationName() -> String {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized: return "authorized"
    case .notDetermined: return "notDetermined"
    case .denied: return "denied"
    case .restricted: return "restricted"
    @unknown default: return "restricted"
    }
  }
}
